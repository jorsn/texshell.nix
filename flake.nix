{
  description = "Easy dev shells for multiple TeXlive versions";

  nixConfig.extra-experimental-features = "nix-command flakes";

  inputs = {

    # flake utils

    utils.url = "github:gytis-ivaskevicius/flake-utils-plus/v1.3.0";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "default";

    ## only nixpkgs nix-library, without whole nixpkgs
    nixlib.url = "github:nix-community/nixpkgs.lib";

    # nixpkgs

    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos.url  = "github:NixOS/nixpkgs/release-24.05";
    nixos-2311.url  = "github:NixOS/nixpkgs/release-23.11";

    tl2023.follows = "unstable";
    tl2022.url # latest nixpkgs commit with texlive 2022 that is prebuilt by hydra
      = "github:NixOS/nixpkgs/62b78e643ce4f7c8d2c62bec040686ba311eb76c";
    tl2021.url # latest nixpkgs commit with texlive 2021
      = "github:NixOS/nixpkgs/cb2f60a2d13a9da2510fa172c0e69ccbf14f18b7";
    tl2012.url # latest nixpkgs commit with texlive 2012 (nearest to ScholarOne's 2013)
      = "github:NixOS/nixpkgs/4dee7de246e6037d494d798efd2a383d9fccc8cc";
    tl2012.flake = false;

    ## defaults
    arxiv.follows = "tl2023";
    nixpkgs.follows = "tl2023";
    default.follows = "nixpkgs";

  };

  outputs =
    { self
    , utils
    , devshell
    , nixlib
    , ...
    }@inputs:

    utils.lib.mkFlake {

      inherit self inputs;

      overlays = utils.lib.exportOverlays { inherit (self) pkgs inputs; };

      channels = with nixlib.lib; {
        tl2012.input = inputs.default;
        tl2012.overlaysBuilder = channels: [
          (final: prev: {
            texlive =
              {
                # back then, the TeX infrastructure in Nixpkgs was very different.
                combined.scheme-full =
                  with prev; with import inputs.tl2012 { inherit (prev) system; };
                  lib.setName "texlive-full" (texLiveAggregationFun {
                    paths = [
                      texLive texLiveExtra lmodern texLiveCMSuper texLiveLatexXColor
                      texLivePGF texLiveBeamer tipa tex4ht texinfo5
                    ];
                  });
              mkShell =
                { name
                , texlivePkg ? final.texlive.combined.scheme-full
                , texdocCmd ? "LC_ALL=C ${texlivePkg}/bin/texlua ${texlivePkg}/libexec/x86_64/texdoc"
                , ...
                }@args:
                prev.texlive.mkShell (args // { inherit texdocCmd; });
              };
          })
        ];
      };

      sharedOverlays = [
        devshell.overlays.default
        (final: prev: with nixlib.lib; {
          texlive = optionalAttrs (prev ? texlive) prev.texlive
            // {
            mkShell =
              { name
              , texlivePkg ? final.texlive.combined.scheme-full
              , texdocCmd ? "${texlivePkg}/bin/texdoc"
              , packages ? []
              }:
              final.devshell.mkShell {
                inherit name;
                commands = [
                  { name = "texdoc"; category = "documentation"; help = "TeX documentation";
                    command = ''${texdocCmd} "$@"'';
                  }
                ];
                packages = packages ++ [ (lowPrio texlivePkg) ];
              };
          };
        })
        (final: prev: with nixlib.lib; {
          texlive =
            let
              tl = prev.texlive;
            in
              recursiveUpdate tl {
                combined.scheme-full = tl.combine {
                  inherit (final.texlive) scheme-full;

                  pkgFilter = p:
                    p.tlType != "source"
                    # add documentation to texlive
                    # texdoc doesn't work in texlive <= 2020 from nixpkgs.
                    # prevent double doc packages
                    && p.pname == "core" -> p.tlType != "doc";
                };
              };
        })
      ];

      outputsBuilder = channels:
        let
          inherit (channels.default) system;
          projName = "texshell";
        in {
          packages = with nixlib.lib;
            utils.lib.exportPackages self.overlays channels
            // flip mapAttrs' channels
              (name: channel: {
                inherit name;
                value = channel.texlive.mkShell {
                  name = "${projName}/${name}";
                  packages = with channel; [ gnumake ]; # make is often needed
                };
              });

          overlay = self.overlays."default/texlive";
        };

      templates.default = {
        path = ./template;
        description = "minimal default template";
      };
    };

}
