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
      echo "Default Rust version: $(rustc --version)"
    '';
  };
in {
  devShells = { rustup = devShellDerivation; };
  sharedEnv = common.env;
}
