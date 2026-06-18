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

        bunDeps = pkgs.stdenv.mkDerivation {
          name = "knip-bun-deps";
          inherit src;
          nativeBuildInputs = [ pkgs.bun pkgs.cacert ];
          buildPhase = ''
            export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache
            # The tarball doesn't contain a lockfile usually, so we generate one or just install
            bun install --production --ignore-scripts
          '';
          installPhase = ''
            mkdir -p $out
            if [ -d node_modules ]; then
              cp -r node_modules $out/
            fi
          '';
          dontFixup = true;
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = "sha256-m/QvOANNDJbMFBwAC9O++sxuHsMIZ2GlxXNnQDwcfPE=";
        };

        knip = pkgs.stdenv.mkDerivation {
          pname = "knip";
          inherit version src;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          
          buildPhase = ''
            if [ -d ${bunDeps}/node_modules ]; then
              cp -r ${bunDeps}/node_modules ./
              chmod -R +w node_modules
            fi
          '';

          installPhase = ''
            mkdir -p $out/libexec/knip $out/bin
            cp -r . $out/libexec/knip
            
            makeWrapper ${pkgs.nodejs_24}/bin/node $out/bin/knip \
              --add-flags "$out/libexec/knip/bin/knip.js"
          '';

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
