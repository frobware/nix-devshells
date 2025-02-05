{
  description = "Development shell for BPF tooling.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems, ... }: let
    forEachSystem = nixpkgs.lib.genAttrs (import systems);

    mkDevShell = system: let
      pkgs = import nixpkgs { inherit system; };
    in pkgs.mkShell {
      nativeBuildInputs = [
        pkgs.just

        pkgs.bcc
        pkgs.bpftools
        pkgs.elfutils
        pkgs.libbpf
        pkgs.linuxHeaders
        pkgs.llvmPackages.clang-unwrapped
      ];

      hardeningDisable = [ "all" ];

      shellHook = ''
        export CC=${pkgs.llvmPackages.clang-unwrapped}/bin/clang
        export CFLAGS="-I${pkgs.linuxHeaders}/include -I${pkgs.libbpf}/include"
        echo CFLAGS=$CFLAGS
      '';
    };
  in {
    devShells = forEachSystem (system: {
      default = mkDevShell system;
    });
  };
}
