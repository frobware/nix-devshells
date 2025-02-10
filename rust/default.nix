{ lib, pkgs, rustVersion }:

let
  # Use|find the source Luke!
  # rustc --print sysroot | xargs -I {} find {} -name "lib.rs" | grep src

  components =
    [ "cargo" "clippy" "rust-analyzer" "rust-src" "rustc" "rustfmt" ];

  rawToolchain = if rustVersion == "nightly" then
    (pkgs.rust-bin.selectLatestNightlyWith
      (toolchain: toolchain.default)).override { extensions = components; }
  else
    (pkgs.rust-bin.${rustVersion}.latest.default).override {
      extensions = components;
    };

  # Ensure all binaries are available in a single directory. I /think/
  # this helps fix my RustRover issues...
  toolchain = pkgs.buildEnv {
    name = "rust-toolchain-${rustVersion}";
    paths = [ rawToolchain ];
    pathsToLink = [ "/bin" ];
  };

  # TODO: We actually want ${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} but I
  # couldn't get this to work; some whacky quoting needed somewhere.
  # The message in commit e6f83660c046abd7e529902906374190ad538c76 is
  # plain wrong. So many Nix battles to fight.
  sharedEnv = {
    LD_LIBRARY_PATH = "${pkgs.openssl.out}/lib:\$LD_LIBRARY_PATH";
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang}/lib:\$LIBCLANG_PATH";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:\$PKG_CONFIG_PATH";
    RUST_SRC_PATH = "${rawToolchain}/lib/rustlib/src/rust/library";
  };

  devShellDerivation = pkgs.mkShell {
    buildInputs = [
      toolchain
      pkgs.clang
      pkgs.cmake
      pkgs.llvmPackages.libclang
      pkgs.llvmPackages_latest.lldb
      pkgs.mold
      pkgs.ninja
      pkgs.openssl
      pkgs.openssl.dev
      pkgs.pkg-config
      pkgs.sqlite
    ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      pkgs.darwin.apple_sdk.frameworks.Security
      pkgs.darwin.apple_sdk.frameworks.CoreFoundation
      pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.gdb pkgs.valgrind ];

    env = sharedEnv;

    shellHook = ''
      export CARGO_TARGET_DIR="/tmp/cargo-target-dir-''${USER:-unknown-user}-$(basename "$PWD")"
      mkdir -p "$CARGO_TARGET_DIR"
      ln -sf "$CARGO_TARGET_DIR" target
      echo CARGO_TARGET_DIR=$CARGO_TARGET_DIR
      echo "🦀🦀🦀 Welcome to your Rust development shell (${rustVersion}) 🦀🦀🦀"
      echo "Rust version: $(rustc --version)"
    '';
  };

in {
  devShells = { ${rustVersion} = devShellDerivation; };
  # Expose `sharedEnv` separately so Home Manager can use it.
  sharedEnv = sharedEnv;
}
