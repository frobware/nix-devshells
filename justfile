# Default to listing available recipes
default:
    @just --list

# Common override arguments used in multiple recipes
override := "--override-input bpf path:" + env_var("PWD") + "/bpf --override-input rust path:" + env_var("PWD") + "/rust"

# Build a specific package (defaults to rust-stable)
build package="rust-stable":
    nix build {{override}} .#{{package}}

# Build all packages
build-all:
    #!/usr/bin/env bash
    set -euo pipefail
    packages=$(nix eval {{override}} --json .#packages.$(nix eval --impure --raw --expr builtins.currentSystem) | jq -r 'keys[]')
    for pkg in $packages; do
        echo "Building $pkg"
        nix build {{override}} .#$pkg
    done

# Install a package to your profile
install package="rust-stable":
    #!/usr/bin/env bash
    set -eux
    nix profile remove {{package}}
    nix profile install {{override}} .#{{package}}

remove package="rust-stable":
    nix profile remove {{package}}

# Quick test a development shell
test-shell shell="rust-stable":
    ./devshell {{shell}}

# Test that the direnv script works correctly
test-direnv package="rust-stable": build
    #!/usr/bin/env bash
    set -euo pipefail

    result=$(readlink -f result)
    flake_dir=$PWD
    declare -a DEVSHELLS_OVERRIDES

    DEVSHELLS_OVERRIDES=(
        "--override-input" "bpf" "path:$flake_dir/bpf"
        "--override-input" "rust" "path:$flake_dir/rust"
    )
    export DEVSHELLS_OVERRIDES

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    echo "Testing direnv script in $tmpdir"
    cd "$tmpdir"

    DEVSHELLS_FLAKE_PATH=$flake_dir DEVSHELLS_OVERRIDES="${DEVSHELLS_OVERRIDES[*]}" "$result/bin/frobware-devshell-{{package}}-build-direnv"
    direnv allow .
    direnv exec . bash -c 'env | grep ^CARGO_TARGET_DIR=' || {
      echo "Error: CARGO_TARGET_DIR is not set in the direnv environment"
      exit 1
    }
