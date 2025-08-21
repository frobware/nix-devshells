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
    pkgs.libiconv
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
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    pkgs.gdb
    pkgs.valgrind
  ];

  rustPkgConfigPaths = pkgs.lib.makeSearchPath "lib/pkgconfig" [
    pkgs.openssl.dev
    pkgs.sqlite.dev
    pkgs.zlib.dev
  ];

  commonEnv =
    {
      LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
      PKG_CONFIG_PATH = rustPkgConfigPaths;
    }
    // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      # Make libiconv discoverable to the linker in pure shells.
      LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libiconv ];

      # Uncomment only if you hit missing <iconv.h>:
      # C_INCLUDE_PATH = "${pkgs.libiconv}/include";
      # CPATH          = "${pkgs.libiconv}/include";
    };

in {
  buildInputs = commonBuildInputs;
  env = commonEnv;
  rustPkgConfigPaths = rustPkgConfigPaths;
  installRustToolchainScript = installRustToolchainScript;
}
