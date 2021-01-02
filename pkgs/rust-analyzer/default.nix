# https://github.com/cargo2nix/cargo2nix/blob/433cd5b53d91a9577e7bfaa910df6b8eb8528bbc/examples/4-independent-packaging/default.nix
{ system, nixpkgs, nixpkgsMozilla, cargo2nix, rustChannel, rustChannelSha256, }:
let
  pkgs = import nixpkgs {
    inherit system;
    overlays = let
      rustOverlay = import "${nixpkgsMozilla}/rust-overlay.nix";
      cargo2nixOverlay = import "${cargo2nix}/overlay";
    in [ cargo2nixOverlay rustOverlay ];
  };

  rustPkgs = pkgs.rustBuilder.makePackageSet' {
    inherit rustChannel rustChannelSha256;
    packageFun = import ./Cargo.nix;

    # https://github.com/rust-analyzer/rust-analyzer/releases
    # nix-prefetch-url --unpack https://github.com/rust-analyzer/rust-analyzer/archive/2020-12-28.tar.gz
    workspaceSrc = pkgs.fetchFromGitHub {
      owner = "rust-analyzer";
      repo = "rust-analyzer";
      rev = "2020-12-28";
      sha256 = "10d6z8fsjcr0z1pb23fayzgcgmh7ss8f4zrahbyc75f6mj2q0c0r";
    };

    localPatterns = [
      "^(src|tests|crates|xtask|assets|templates)(/.*)?"
      "[^/]*\\.(rs|toml)$"
    ];
  };

in { rust-analyzer = (rustPkgs.workspace.rust-analyzer { }).bin; }
