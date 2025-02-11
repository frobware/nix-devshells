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

  sharedEnv = let
    extraRustflags = if pkgs.stdenv.isDarwin then
      "-C link-arg=-fuse-ld=/usr/bin/ld"
    else
      "-C link-arg=-fuse-ld=${pkgs.mold}/bin/mold";
  in {
    LD_LIBRARY_PATH = "${lib.makeLibraryPath [ pkgs.openssl ]}";
    LIBCLANG_PATH = "${lib.makeLibraryPath [ pkgs.llvmPackages.libclang.lib ]}";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    RUSTFLAGS = "-C link-args=-Wl,-rpath,${lib.makeLibraryPath [ pkgs.openssl ]} ${extraRustflags}";
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
      echo "🦀🦀🦀 Welcome to your Rust development shell (${rustVersion}) 🦀🦀🦀"
      echo "Rust version: $(rustc --version)"
      echo "Cargo version: $(cargo --version)"
    '';
  };

in {
  devShells = { ${rustVersion} = devShellDerivation; };
  # Expose `sharedEnv` separately so Home Manager can use it.
  sharedEnv = sharedEnv;
}
