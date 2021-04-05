{
  description = "A flake and overlay for Rust Analyzer via cargo2nix";

  inputs = {
    cargo2nix = {
      url = "github:cargo2nix/cargo2nix";
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
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            (import inputs.rust-overlay)
            (import "${inputs.cargo2nix}/overlay")
          ];
        };

        rustChannel = "stable";

        mkCargo2NixPackage = path:
          pkgs.callPackage path {
            inherit nixpkgs rustChannel system;
            inherit (inputs) cargo2nix rust-overlay;
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
            inherit nixpkgs rustChannel system;
          }).package;
        };

        defaultPackage = pkgs.linkFarmFromDrvs "rust-analyzer-packages"
          (builtins.attrValues self.packages."${system}");
      });
}
