{
  description = "A collection of development shells.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    bpf.url = "github:frobware/nix-devshells?dir=bpf";
    rust.url = "github:frobware/nix-devshells?dir=rust";
  };

  outputs = { self, nixpkgs, rust, bpf, ... }@inputs:
    let eachSystem = nixpkgs.lib.genAttrs (import inputs.systems);
    in {
      # We explicitly merge named devShells from `rust` and `bpf` to
      # avoid duplicate `default` entries.
      #
      # Specifically, we:
      # - Filter for Rust shells with `rust` prefix
      # - Add BPF shells if defined for the current system
      devShells = eachSystem (system:
        nixpkgs.lib.recursiveUpdate
        (nixpkgs.lib.filterAttrs (name: _: nixpkgs.lib.hasPrefix "rust" name)
          rust.devShells.${system})
        (nixpkgs.lib.optionalAttrs (bpf.devShells ? ${system}) {
          bpf = bpf.devShells.${system}.default;
        }));

      # The apps entry primarily supports nix run, allowing users to
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
      # nix eval --override-input bpf path:./bpf --override-input rust path:./rust --json .#apps | jq .
      apps = eachSystem (system:
        nixpkgs.lib.genAttrs (builtins.attrNames (self.devShells.${system}))
        (shell: {
          type = "app";
          program = toString (self.packages.${system}.${shell});
        }));

      # The packages entry primarily supports Nix profiles, allowing
      # users to install the development shells as system-wide commands.
      #
      #  nix profile install github:frobware/nix-devshells#bpf
      #  nix profile install github:frobware/nix-devshells#rust-stable
      #  nix profile install github:frobware/nix-devshells#rust-beta
      #  nix profile install github:frobware/nix-devshells#rust-nightly
      #
      # Check this locally with:
      #
      # nix eval --override-input bpf path:./bpf --override-input rust path:./rust --json .#packages | jq .
      packages = eachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in nixpkgs.lib.genAttrs (builtins.attrNames (self.devShells.${system}))
        (shell:
          pkgs.symlinkJoin {
            name = "frobware-devshell-${shell}";
            paths = [
              (pkgs.writeShellScriptBin "frobware-devshell-${shell}-build-direnv" ''
                set -euo pipefail
                echo "Building direnv environment for ${shell}..."

                cat > .envrc <<EOF
                if [[ -n "''${DEVSHELLS_OVERRIDES:-}" ]]; then
                  if [[ ! -f .envrc.cache || .envrc -nt .envrc.cache ]]; then
                    nix print-dev-env $DEVSHELLS_OVERRIDES "$DEVSHELLS_FLAKE_PATH#${shell}" > .envrc.cache
                  fi
                else
                  nix print-dev-env github:frobware/nix-devshells#${shell} > .envrc.cache
                fi

                source .envrc.cache
                EOF
              '')
            ];
          }));
    };
}
