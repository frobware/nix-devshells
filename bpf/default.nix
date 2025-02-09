{ pkgs }:

if pkgs.stdenv.isLinux then
pkgs.mkShell {
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
    echo "🔧 BPF development shell initialised"
    echo "CFLAGS=$CFLAGS"
  '';
}
else
pkgs.mkShell {
  shellHook = ''
    echo "BPF development is only supported on Linux systems." >&2
    exit 1
  '';
}
