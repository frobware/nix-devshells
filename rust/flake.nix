{
  description = "A flake providing Rust development shells with stable, beta, and nightly toolchains.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    systems.url = "github:nix-systems/default";
  };
  outputs = { self, nixpkgs, rust-overlay, ... } @ inputs:
  let
    eachSystem = nixpkgs.lib.genAttrs (import inputs.systems);

    mkRustDevShell = system: rustVersion: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
      };
      toolchain = (if rustVersion == "nightly" then
        pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default)
      else
        pkgs.rust-bin.${rustVersion}.latest.default);
    in pkgs.mkShell {
      buildInputs = [
        toolchain

        # Build essentials
        pkgs.clang
        pkgs.cmake
        pkgs.llvmPackages.libclang
        pkgs.mold
        pkgs.ninja
        pkgs.pkg-config

        # Development tools
        pkgs.llvmPackages_latest.lldb
        pkgs.rust-analyzer

        # Libraries
        pkgs.openssl
        pkgs.openssl.dev
        pkgs.sqlite
      ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        pkgs.darwin.apple_sdk.frameworks.Security
        pkgs.darwin.apple_sdk.frameworks.CoreFoundation
        pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
      ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        pkgs.gdb
        pkgs.valgrind
      ];

      env = {
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
        RUST_BACKTRACE = "1";
        RUSTFLAGS = if pkgs.stdenv.isDarwin then
          "-C link-arg=-fuse-ld=/usr/bin/ld"
        else
          "-C link-arg=-fuse-ld=mold";
      };

      shellHook = ''
        # Reference a target directory that is on local storage - useful when building over NFS.
        export CARGO_TARGET_DIR="/tmp/cargo-target-dir-''${USER:-unknown-user}-$(basename "$PWD")"
        mkdir -p "''$CARGO_TARGET_DIR"
        ln -sf "$CARGO_TARGET_DIR" target
        echo CARGO_TARGET_DIR=$CARGO_TARGET_DIR
        echo "🦀🦀🦀 Welcome to your Rust development shell (${rustVersion}) 🦀🦀🦀"
        echo "Rust version: $(rustc --version)"
      '';
    };
  in {
    devShells = eachSystem (system: rec {
      # Standard versioned shells
      "rust-stable" = mkRustDevShell system "stable";
      "rust-beta" = mkRustDevShell system "beta";
      "rust-nightly" = mkRustDevShell system "nightly";
      # Default shell (stable)
      default = mkRustDevShell system "stable";
      "rust" = default;
    });
  };
}
