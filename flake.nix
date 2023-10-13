{
  description = "Telemetrex as a flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    lexical-lsp.url = "github:lexical-lsp/lexical";
  };

  outputs = { self, nixpkgs, flake-utils, lexical-lsp }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (pkgs.lib) optional optionals;
        pkgs = import nixpkgs { inherit system; };
        elixir = pkgs.beam.packages.erlang.elixir;
      in
      with pkgs;
      {
        devShell = pkgs.mkShell {
          buildInputs = [ 
            elixir_1_15
            postgresql_12
            lexical-lsp.packages.${system}.lexical
            glibcLocales
          ] ++ optional stdenv.isLinux inotify-tools;
        };
      });
}
