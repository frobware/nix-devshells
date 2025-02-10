{ lib, pkgs, rustVersion }:

let
  toolchain = if rustVersion == "nightly" then
    pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default)
  else
    pkgs.rust-bin.${rustVersion}.latest.default;

  # Shared environment variables (NOT returned in devShells).
  sharedEnv = {
    LD_LIBRARY_PATH = "${pkgs.openssl.out}/lib:$LD_LIBRARY_PATH";
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang}/lib:$LIBCLANG_PATH";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:$PKG_CONFIG_PATH";
  };

  # Generate shellHook to export sharedEnv variables dynamically.
  exportEnvHook = lib.concatStringsSep "\n"
    (map (k: "export ${k}='${sharedEnv.${k}}'") (builtins.attrNames sharedEnv));

  interactiveShellHook = ''
    export CARGO_TARGET_DIR="/tmp/cargo-target-dir-''${USER:-unknown-user}-$(basename "$PWD")"
    mkdir -p "$CARGO_TARGET_DIR"
    ln -sf "$CARGO_TARGET_DIR" target
    echo CARGO_TARGET_DIR=$CARGO_TARGET_DIR
    echo "🦀🦀🦀 Welcome to your Rust development shell (${rustVersion}) 🦀🦀🦀"
    echo "Rust version: $(rustc --version)"
  '';

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
      pkgs.rust-analyzer
      pkgs.sqlite
    ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      pkgs.darwin.apple_sdk.frameworks.Security
      pkgs.darwin.apple_sdk.frameworks.CoreFoundation
      pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.gdb pkgs.valgrind ];

    shellHook =
      lib.concatStringsSep "\n" [ exportEnvHook interactiveShellHook ];
  };

in {
  devShells = { ${rustVersion} = devShellDerivation; };
  # Expose `sharedEnv` separately so Home Manager can use it.
  sharedEnv = sharedEnv;
}
