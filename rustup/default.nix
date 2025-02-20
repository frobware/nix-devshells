{ pkgs, ... }:

pkgs.mkShell {
  name = "rustup-devshell";

  buildInputs = [
    pkgs.cargo-edit
    pkgs.clang
    pkgs.cmake
    pkgs.diesel-cli
    pkgs.llvmPackages.libclang
    pkgs.llvmPackages_latest.lldb
    pkgs.mold-wrapped
    pkgs.ninja
    pkgs.openssl
    pkgs.openssl.dev
    pkgs.pkg-config
    pkgs.rustup
    pkgs.sqlite
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pkgs.darwin.apple_sdk.frameworks.CoreFoundation
    pkgs.darwin.apple_sdk.frameworks.Security
    pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    pkgs.iconv
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    pkgs.gdb
    pkgs.valgrind
  ];

  env = {};

  shellHook = ''
    echo "🦀 Using Nix's rustup for Rust toolchains 🦀"
    echo "Rustup version: $(rustup --version)"
    echo "Default Rust version: $(rustc --version)"
  '';
}
