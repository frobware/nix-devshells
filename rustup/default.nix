{ pkgs, ... }:

let
  common = import ../rust/common.nix { inherit pkgs; };

  devShellDerivation = pkgs.mkShell {
    name = "rustup";
    buildInputs = common.buildInputs ++ [ pkgs.rustup ];
    env = common.env;

    shellHook = ''
      echo "🦀 Using Nix's rustup for Rust toolchains 🦀"
      echo "Rustup version: $(rustup --version)"

      if rustc --version >/dev/null 2>&1; then
        echo "Rustc version: $(rustc --version)"
      else
        echo "Warning: No Rust toolchain detected!"
        echo "Run 'rustup default stable' to install the latest stable Rust version."
      fi

      echo "Use 'nix-rustup-install-toolchain' to install a specific Rust toolchain together with its development components."
    '';
  };
in {
  devShells = { rustup = devShellDerivation; };
  sharedEnv = common.env;
}
