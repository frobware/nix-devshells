{ lib, pkgs, rustVersion }:

let
  common = import ./common.nix { inherit pkgs; };

  components =
    [ "cargo" "clippy" "rust-analyzer" "rust-src" "rustc" "rustfmt" "clippy-preview" ];

    rawToolchain = if rustVersion == "nightly" then
    (pkgs.rust-bin.selectLatestNightlyWith
    (toolchain: toolchain.default)).override { extensions = components; }
    else
    (pkgs.rust-bin.${rustVersion}.latest.default).override {
      extensions = components;
    };

    toolchain = pkgs.buildEnv {
      name = "rust-toolchain-${rustVersion}";
      paths = [ rawToolchain ];
      pathsToLink = [ "/bin" ];
    };

    devShellDerivation = pkgs.mkShell {
      buildInputs = [ toolchain ] ++ common.buildInputs;
      env = common.env;

      shellHook = ''
        echo "🦀🦀🦀 Welcome to your ${rustVersion} Rust development shell 🦀🦀🦀"
        echo "Rust version: $(rustc --version)"
        echo "Cargo version: $(cargo --version)"
      '';
    };
in {
  devShells = { ${rustVersion} = devShellDerivation; };
  sharedEnv = common.env;
}
