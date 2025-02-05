{
  description = "A collection of reusable development shells.";

  inputs = {
    systems.url = "github:nix-systems/default";
    bpf.url = "path:./bpf";
    rust.url = "path:./rust";
  };

  outputs = { self, systems, bpf, rust, ... }:
    let
      forEachSystem = system: {
        bpf = bpf.devShells.${system}.default;
        rust = rust.devShells.${system}.default;
      };
    in {
      devShells = builtins.listToAttrs (map (system: {
        name = system;
        value = forEachSystem system;
      }) (import systems));
    };
}
