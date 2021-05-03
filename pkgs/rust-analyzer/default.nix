# https://github.com/cargo2nix/cargo2nix/blob/ebef37673009af79814528b1bc42ec30d7a25012/examples/4-independent-packaging/default.nix
{ system, nixpkgs, cargo2nix, rust-overlay, rustChannel }:
let
  pkgs = import nixpkgs {
    inherit system;
    overlays = let
      rustOverlay = import rust-overlay;
      cargo2nixOverlay = import "${cargo2nix}/overlay";
    in [ cargo2nixOverlay rustOverlay ];
  };

  rustPkgs = pkgs.rustBuilder.makePackageSet' {
    inherit rustChannel;
    packageFun = import ./Cargo.nix;

    # https://github.com/rust-analyzer/rust-analyzer/releases
    # nix-prefetch-url --unpack https://github.com/rust-analyzer/rust-analyzer/archive/2021-05-03.tar.gz
    workspaceSrc = pkgs.fetchFromGitHub {
      owner = "rust-analyzer";
      repo = "rust-analyzer";
      rev = "2021-05-03";
      sha256 = "0y5s3yyg0d7mgrwyhgxxsjcdri0x8y3kzddxqm0kfykhgswwiabw";
    };

    localPatterns = [
      ''^(src|tests|crates|xtask|assets|templates)(/.*)?''
      ''[^/]*\.(rs|toml)$''
    ];
  };

in { rust-analyzer = (rustPkgs.workspace.rust-analyzer { }).bin; }
