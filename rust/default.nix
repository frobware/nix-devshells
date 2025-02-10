{ pkgs, rustVersion }:

let
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
    pkgs.llvmPackages_latest.lldb
    pkgs.mold
    pkgs.ninja
    pkgs.openssl
    pkgs.openssl.dev
    pkgs.pkg-config
    pkgs.rust-analyzer
    pkgs.sqlite
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pkgs.darwin.apple_sdk.frameworks.Security
    pkgs.darwin.apple_sdk.frameworks.CoreFoundation
    pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.gdb pkgs.valgrind ];

  env = {
    LD_LIBRARY_PATH = "${pkgs.openssl.out}/lib:$LD_LIBRARY_PATH";
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:$PKG_CONFIG_PATH";
    RUSTFLAGS = if pkgs.stdenv.isDarwin then
      "-C link-arg=-fuse-ld=/usr/bin/ld"
    else
      "-C link-arg=-fuse-ld=mold";
    RUST_BACKTRACE = "1";
  };

  shellHook = ''
    export CARGO_TARGET_DIR="/tmp/cargo-target-dir-''${USER:-unknown-user}-$(basename "$PWD")"
    mkdir -p "$CARGO_TARGET_DIR"
    ln -sf "$CARGO_TARGET_DIR" target
    echo CARGO_TARGET_DIR=$CARGO_TARGET_DIR
    echo "🦀🦀🦀 Welcome to your Rust development shell (${rustVersion}) 🦀🦀🦀"
    echo "Rust version: $(rustc --version)"
  '';
}
