{
  description = "Use old TeXlive versions";

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
    nixos.url = "github:NixOS/nixpkgs/release-22.05";
    tl2020.url # latest nixpkgs commit with texlive 2020
      = "github:NixOS/nixpkgs/ca44268569be4eb348b24bc0705e0482b9ea87a1";
    tl2012.url # latest nixpkgs commit with texlive 2012 (nearest to ScholarOne's 2013)
      = "github:NixOS/nixpkgs/4dee7de246e6037d494d798efd2a383d9fccc8cc";
    tl2012.flake = false;

    ## defaults
    tl2021.follows = "nixos";
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

      channels.tl2012.input = inputs.default;
      channels.tl2012.overlaysBuilder = channels: [
        (final: prev: {
          texlive = with import inputs.tl2012 { inherit (prev) system; }; {
            combined.scheme-full = lib.setName "texlive-full" (texLiveAggregationFun {
              paths = [
                texLive texLiveExtra lmodern texLiveCMSuper texLiveLatexXColor
                texLivePGF texLiveBeamer tipa tex4ht texinfo5
              ];
            });
          };
        })
      ];

      sharedOverlays = [ devshell.overlay ];

      outputsBuilder = channels:
        let
          inherit (channels.default) system;
          projName = "ancienTeX";
        in {
          packages = with nixlib.lib;
            utils.lib.exportPackages self.overlays channels
            // flip mapAttrs' channels
              (name: channel: nameValuePair "dev/${name}" (channel.devshell.mkShell {
                name = "${projName}-devShell-${name}";
                env = [
                  {
                    name = "LC_ALL";
                    value = "C";
                }];
                devshell.startup = {
                  texdoc.text = "alias texdoc='texlua ${channel.texlive.combined.scheme-full}/libexec/x86_64/texdoc'";
                };
                packages = [
                  (if name == "tl2012"
                    then channel.texlive.combined.scheme-full
                    else with channel.texlive; combine {

                      inherit scheme-full;

                      pkgFilter = pkg:
                        pkg.tlType != "source"
                        && pkg.pname != projName
                        # texdoc doesn't work in texlive <= 2020 from nixpkgs.
                        && (pkg.pname == "core" || toInt bin.core.version <= 2020) -> pkg.tlType != "doc";
                  })
                ];
              }))
            // { default = self.packages.${system}."devshell/default"; };

          overlay = self.overlays.default;

          apps = {
            texdoc = utils.lib.mkApp { # use this when using texlive <= 2020. Since 2021, texdoc works natively
              drv = self.devShells.${system}.nixos;
              exePath = "/bin/texdoc";
            };
          };

        };

      templates.default = {
        path = ./template;
        description = "minimal default template";
      };
    };

}
