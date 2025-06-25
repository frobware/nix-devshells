{ pkgs, ... }:

let
  installRustToolchainScript = pkgs.writeShellScriptBin "nix-rustup-install-toolchain" ''
    #!/usr/bin/env bash
    set -euo pipefail
    toolchain="''${1:-stable}"
    profile="''${2:-default}"
    rustup set profile "$profile"
    rustup toolchain install "$toolchain"
    rustup component add \
           clippy \
           rust-analyzer \
           rust-docs \
           rust-src \
           rust-std \
           rustfmt \
           --toolchain "$toolchain"
    rustup update "$toolchain"
  '';

  commonBuildInputs = [
    installRustToolchainScript

    pkgs.cargo-edit
    pkgs.clang
    pkgs.cmake
    pkgs.diesel-cli
    pkgs.elfutils # For libelf development headers
    pkgs.llvmPackages.libclang
    pkgs.llvmPackages_latest.lldb
    pkgs.mold-wrapped
    pkgs.ninja
    pkgs.openssl
    pkgs.openssl.dev
    pkgs.pkg-config
    pkgs.sqlite
    pkgs.sqlite.dev
    pkgs.zlib
    pkgs.zlib.dev
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pkgs.darwin.apple_sdk.frameworks.CoreFoundation
    pkgs.darwin.apple_sdk.frameworks.Security
    pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    pkgs.iconv
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    pkgs.gdb
    pkgs.valgrind
  ];

  commonEnv = {
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.sqlite.dev}/lib/pkgconfig:${pkgs.zlib.dev}/lib/pkgconfig:${pkgs.elfutils.dev}/lib/pkgconfig";
    # Help libbpf-sys find libelf headers
    C_INCLUDE_PATH = "${pkgs.elfutils.dev}/include";
    CPLUS_INCLUDE_PATH = "${pkgs.elfutils.dev}/include";
  };

in {
  buildInputs = commonBuildInputs;
  env = commonEnv;
  installRustToolchainScript = installRustToolchainScript;
}
