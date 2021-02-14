{
  description = "A flake and overlay for Rust Analyzer via cargo2nix";

  inputs = {
    cargo2nix = {
      # Primarily for https://github.com/cargo2nix/cargo2nix/commit/e37f3788b97ba4607813e41da409a7fd6db8a523
      url =
        "github:cargo2nix/cargo2nix/433cd5b53d91a9577e7bfaa910df6b8eb8528bbc";
      flake = false;
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
    nixpkgs.url = "nixpkgs/nixos-20.09";
  };

  outputs = inputs@{ self, flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            (import inputs.nixpkgs-mozilla)
            (import "${inputs.cargo2nix}/overlay/default.nix")
          ];
        };

        rustChannel = "1.50.0";
        rustChannelSha256 = "PkX/nhR3RAi+c7W6bbphN3QbFcStg49hPEOYfvG51lA=";

        mkCargo2NixPackage = path:
          pkgs.callPackage path {
            inherit nixpkgs rustChannel rustChannelSha256 system;
            cargo2nix = inputs.cargo2nix;
            nixpkgsMozilla = inputs.nixpkgs-mozilla;
          };
      in {
        devShell = pkgs.mkShell {
          buildInputs = [ self.packages."${system}".cargo2nix ];

          NIX_PATH = "nixpkgs=${nixpkgs}";
        };

        packages = {
          rust-analyzer =
            (mkCargo2NixPackage ./pkgs/rust-analyzer).rust-analyzer.bin;

          cargo2nix = (import inputs.cargo2nix {
            inherit nixpkgs rustChannel rustChannelSha256 system;
            nixpkgsMozilla = inputs.nixpkgs-mozilla;
          }).package;
        };

        defaultPackage = pkgs.linkFarmFromDrvs "rust-analyzer-packages"
          (builtins.attrValues self.packages."${system}");
      });
}
