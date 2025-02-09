{ pkgs, rustVersion }:

let
  # Select the appropriate Rust toolchain version
  toolchain = if rustVersion == "nightly" then
  pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default)
  else
  pkgs.rust-bin.${rustVersion}.latest.default;
in pkgs.mkShell {
  buildInputs = [
    toolchain
    pkgs.clang
    pkgs.cmake
    pkgs.llvmPackages.libclang
    pkgs.mold
    pkgs.ninja
    pkgs.pkg-config
    pkgs.llvmPackages_latest.lldb
    pkgs.rust-analyzer
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
    export CARGO_TARGET_DIR="/tmp/cargo-target-dir-''${USER:-unknown-user}-$(basename "$PWD")"
    mkdir -p "''$CARGO_TARGET_DIR"
    ln -sf "$CARGO_TARGET_DIR" target
    echo CARGO_TARGET_DIR=$CARGO_TARGET_DIR
    echo "🦀🦀🦀 Welcome to your Rust development shell (${rustVersion}) 🦀🦀🦀"
    echo "Rust version: $(rustc --version)"
  '';
}
