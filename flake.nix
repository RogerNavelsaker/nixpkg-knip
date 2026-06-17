{
  description = "Nix packaging scaffold for knip";

  nixConfig = {
    extra-substituters = [ "https://cache.nixos.org" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in {
      packages = forAllSystems ({ pkgs }: {
        default = pkgs.buildNpmPackage rec {
          pname = "knip";
          version = "5.21.2";

          src = pkgs.fetchFromGitHub {
            owner = "webpro";
            repo = "knip";
            rev = version;
            hash = pkgs.lib.fakeHash;
          };

          npmDepsHash = pkgs.lib.fakeHash;

          meta = with pkgs.lib; {
            description = "Find unused files, dependencies and exports in your JavaScript and TypeScript projects";
            homepage = "https://knip.dev";
            license = licenses.isc;
            mainProgram = "knip";
          };
        };
      });

      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ nix-update ];
        };
      });
    };
}
