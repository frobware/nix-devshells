{
  description = "A collection of development shells.";

  inputs = {
    # To override the inputs on an ad-hoc basis:
    # $ nix develop --override-input nixpkgs github:NixOS/nixpkgs/nixos-24.11 .#rust-stable
    # $ nix build --override-input nixpkgs github:NixOS/nixpkgs/nixos-24.11 .#rust-stable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, rust-overlay, ... }@inputs:
    let eachSystem = nixpkgs.lib.genAttrs (import inputs.systems);
    in {
      devShells = eachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };

          bpf = import ./bpf/default.nix { inherit pkgs; };

          mkRustDevShell = rustVersion:
            import ./rust/default.nix { inherit pkgs rustVersion; };
        in {
          bpf = bpf;
          rust-beta = mkRustDevShell "beta";
          rust-nightly = mkRustDevShell "nightly";
          rust-stable = mkRustDevShell "stable";
        });

      # The apps entry primarily supports nix run, allowing me to
      # quickly enter a development shell without needing to remember
      # nix develop commands.
      #
      #  nix run github:frobware/nix-devshells#bpf
      #  nix run github:frobware/nix-devshells#rust-stable
      #  nix run github:frobware/nix-devshells#rust-beta
      #  nix run github:frobware/nix-devshells#rust-nightly
      #
      # Check this locally with:
      #
      # nix eval . #apps | jq .
      apps = eachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in nixpkgs.lib.genAttrs (builtins.attrNames (self.devShells.${system}))
        (shell: {
          type = "app";
          program = toString
            (pkgs.writeShellScript "frobware-devshell-${shell}" ''
              #!/bin/sh
              exec nix develop ${self}#${shell} --command $SHELL
            '');
        }));

      # The packages entry primarily supports Nix profiles, allowing
      # me to install the development shells bootstrap scripts as
      # system-wide commands.
      #
      #  nix profile install github:frobware/nix-devshells#bpf
      #  nix profile install github:frobware/nix-devshells#rust-stable
      #  nix profile install github:frobware/nix-devshells#rust-beta
      #  nix profile install github:frobware/nix-devshells#rust-nightly
      #
      # Check this locally with:
      #
      # nix eval --json .#packages | jq .
      packages = eachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in nixpkgs.lib.genAttrs (builtins.attrNames (self.devShells.${system}))
        (shell:
          pkgs.symlinkJoin {
            name = "frobware-devshell-${shell}";
            paths = [
              (pkgs.writeShellScriptBin
                "frobware-devshell-${shell}-build-direnv" ''
                  set -euo pipefail
                  echo "$PWD: Building direnv environment for ${shell}..."

                  cat > .envrc <<EOF
                  if [[ ! -f .envrc.cache || .envrc -nt .envrc.cache ]]; then
                    nix print-dev-env "${self}#${shell}" > .envrc.cache
                  fi

                  source .envrc.cache
                  EOF
                '')
            ];
          }));

      overlays = {
        default = final: prev: { devShells = self.devShells.${prev.system}; };
      };
    };
}
