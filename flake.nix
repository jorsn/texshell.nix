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
    nixos.url = "github:NixOS/nixpkgs/release-22.11";
    tl2021.url # latest nixpkgs commit with texlive 2021
      = "github:NixOS/nixpkgs/cb2f60a2d13a9da2510fa172c0e69ccbf14f18b7";
    tl2020.url # latest nixpkgs commit with texlive 2020
      = "github:NixOS/nixpkgs/ca44268569be4eb348b24bc0705e0482b9ea87a1";
    tl2012.url # latest nixpkgs commit with texlive 2012 (nearest to ScholarOne's 2013)
      = "github:NixOS/nixpkgs/4dee7de246e6037d494d798efd2a383d9fccc8cc";
    tl2012.flake = false;

    ## defaults
    tl2022.follows = "unstable";
    arxiv.follows = "tl2020"; # see https://arxiv.org/help/faq/texlive
    nixpkgs.follows = "nixos";
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
      }
      # prior to TeXlive 2021, texdoc in Nixpkgs was broken, so we refer to 2021's texdoc in old versions
      // genAttrs [ "tl2020" "arxiv" ] (_: {
        overlaysBuilder = channels: [ (final: prev: {
          texlive =
            prev.texlive
            // {
              mkShell =
                { name
                , texdocCmd ? "${channels.default.texlive.combined.scheme-full}/bin/texdoc"
                , ...
                }@args:
                prev.texlive.mkShell (args // { inherit texdocCmd; });
            };
        }) ];
      });

      sharedOverlays = [
        devshell.overlay
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
              tlDoc = recursiveUpdate tl {
                combined.scheme-full = tl.combine {
                  inherit (tl) scheme-full;

                  pkgFilter = pkg:
                    pkg.tlType != "source"
                    # add documentation to texlive
                    # texdoc doesn't work in texlive <= 2020 from nixpkgs.
                    # prevent double doc packages
                    && pkg.pname == "core" -> pkg.tlType != "doc";
                };
              };
            in if tl ? bin && toInt tl.bin.core.version >= 2021 then tlDoc else tl;
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
                value = channel.texlive.mkShell { name = "${projName}/${name}"; };
              });

          overlay = self.overlays."default/texlive";
        };

      templates.default = {
        path = ./template;
        description = "minimal default template";
      };
    };

}
