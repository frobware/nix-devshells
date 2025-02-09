# Default to listing available recipes
default:
    @just --list

# Build a specific package (defaults to rust-stable)
build package="rust-stable":
    nix build .#{{package}}

# Build all packages
build-all:
    #!/usr/bin/env bash
    set -euo pipefail
    packages=$(nix eval --json .#packages.$(nix eval --impure --raw --expr builtins.currentSystem) | jq -r 'keys[]')
    for pkg in $packages; do
        echo "Building $pkg"
        nix build .#$pkg
    done

install-profile package="rust-stable":
    nix profile install .#{{package}}

upgrade-profile package="rust-stable":
    nix profile install .#{{package}}

remove-profile package="rust-stable":
    nix profile remove .#{{package}}

local-install-profile package="rust-stable": build
    nix profile remove "frobware-devshell-{{package}}" || true
    nix profile install "$(readlink -f result)"

# Quick test a development shell
test-shell shell="rust-stable":
    ./devshell {{shell}}

# Test that the direnv script works correctly.
test-direnv package="rust-stable": build
    #!/usr/bin/env bash
    set -euo pipefail

    result=$(readlink -f result)
    flake_dir=$PWD

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    echo "Testing direnv script in $tmpdir"
    cd "$tmpdir"

    # Build .envrc.
    "$result/bin/frobware-devshell-{{package}}-build-direnv"

    direnv allow .
    direnv exec . bash -c 'env | grep ^CARGO_TARGET_DIR=' || {
      echo "Error: CARGO_TARGET_DIR is not set in the direnv environment." >&2
      exit 1
    }
