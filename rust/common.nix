{ pkgs, ... }:

let
  commonBuildInputs = [
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

  commonEnv = {
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.sqlite.dev}/lib/pkgconfig:${pkgs.zlib.dev}/lib/pkgconfig";
  };

in {
  buildInputs = commonBuildInputs;
  env = commonEnv;
}
