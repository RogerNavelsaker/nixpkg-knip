{
  description = "Nix packaging scaffold for knip";

  nixConfig = {
    extra-substituters = [ "https://cache.nixos.org" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        version = "5.21.2";

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/knip/-/knip-${version}.tgz";
          hash = "sha256-eiETJp2J7ETB6VG0bCVcPKd0JQ+V2X0h5Y3NvRySBT4=";
        };

        knip = pkgs.buildNpmPackage {
          pname = "knip";
          inherit version src;
          postPatch = ''
            cp ${./package-lock.json} package-lock.json
          '';
          npmDepsFetcherVersion = 2;
          npmDepsHash = "sha256-xUj+jeDEX/HRqamVIH6QN3xfDHqs5YuyoD1AYgHHQ2s=";
          npmFlags = [
            "--ignore-scripts"
            "--legacy-peer-deps"
          ];
          npmInstallFlags = [ "--include=dev" ];
          npmPruneFlags = [ "--include=dev" ];
          dontNpmBuild = true;

          meta = with pkgs.lib; {
            description = "Find unused files, dependencies and exports in your JavaScript and TypeScript projects";
            homepage = "https://knip.dev";
            license = licenses.isc;
            mainProgram = "knip";
          };
        };
      in
      {
        packages = {
          inherit knip;
          default = knip;
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nix-update ];
        };
      }
    );
}
