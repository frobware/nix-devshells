{
  description = "Development shell for BPF.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default";
  };
  outputs = { self, nixpkgs, ... } @ inputs:
  let
    eachSystem = nixpkgs.lib.genAttrs (import inputs.systems);
    mkDevShell = system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    if pkgs.stdenv.isLinux then {
      default = pkgs.mkShell {
        buildInputs = [
          pkgs.just
          pkgs.bcc
          pkgs.bpftools
          pkgs.elfutils
          pkgs.libbpf
          pkgs.linuxHeaders
          pkgs.llvmPackages.clang-unwrapped
        ];
        hardeningDisable = [ "all" ];
        env = {
          CC = "${pkgs.llvmPackages.clang-unwrapped}/bin/clang";
          CFLAGS = "-I${pkgs.linuxHeaders}/include -I${pkgs.libbpf}/include";
        };
        shellHook = ''
          echo "🔧 BPF development shell initialized"
          echo "CFLAGS=$CFLAGS"
        '';
      };
    } else {
      default = pkgs.mkShell {
        shellHook = ''
          echo "BPF development is only supported on Linux systems." >&2
          exit 1
        '';
      };
    };
  in {
    devShells = eachSystem mkDevShell;
  };
}
