{ pkgs, ... }:

pkgs.mkShell {
  buildInputs = [
    pkgs.just
    pkgs.bcc
    pkgs.bpftools
    pkgs.elfutils
    pkgs.elfutils.dev
    pkgs.libbpf
    pkgs.linuxHeaders
    pkgs.llvmPackages.clang-unwrapped
  ];
  hardeningDisable = [ "all" ];
  env = {
    CC = "${pkgs.llvmPackages.clang-unwrapped}/bin/clang";
    CFLAGS = "-I${pkgs.linuxHeaders}/include -I${pkgs.libbpf}/include -I${pkgs.elfutils.dev}/include";
    PKG_CONFIG_PATH = pkgs.lib.makeSearchPath "lib/pkgconfig" [ pkgs.libbpf pkgs.elfutils.dev ];
    # Help libbpf-sys find libelf headers
    C_INCLUDE_PATH = "${pkgs.elfutils.dev}/include";
    CPLUS_INCLUDE_PATH = "${pkgs.elfutils.dev}/include";
  };
  shellHook = ''
    echo "🔧 BPF development shell initialised"
    echo "CFLAGS=$CFLAGS"
    echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
  '';
}
