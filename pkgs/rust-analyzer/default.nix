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
    # nix-prefetch-url --unpack https://github.com/rust-analyzer/rust-analyzer/archive/2021-01-25.tar.gz
    workspaceSrc = pkgs.fetchFromGitHub {
      owner = "rust-analyzer";
      repo = "rust-analyzer";
      rev = "2021-01-25";
      sha256 = "1r42cnx5kplql810zc5bcpl0zzm9l8gls64h32nvd7fgad4ixapz";
    };

    localPatterns = [
      "^(src|tests|crates|xtask|assets|templates)(/.*)?"
      "[^/]*\\.(rs|toml)$"
    ];
  };

in { rust-analyzer = (rustPkgs.workspace.rust-analyzer { }).bin; }
