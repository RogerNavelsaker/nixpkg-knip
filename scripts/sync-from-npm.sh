#!/usr/bin/env bash
# Bump knip to the latest npm release: version, tarball hash, package-lock.json, npmDepsHash.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
new=$(curl -fsS https://registry.npmjs.org/knip/latest | jq -r .version)
old=$(grep -oE '^        version = "[^"]+"' flake.nix | sed -E 's/.*"([^"]+)"/\1/')
[ "$new" != "$old" ] || { echo "up to date: $old"; exit 0; }
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
curl -fsS "https://registry.npmjs.org/knip/-/knip-$new.tgz" -o "$work/knip.tgz"
tar -xzf "$work/knip.tgz" -C "$work"
(cd "$work/package" && nix run nixpkgs#nodejs -- "$(nix build nixpkgs#nodejs --no-link --print-out-paths)/lib/node_modules/npm/bin/npm-cli.js" install --package-lock-only --ignore-scripts --legacy-peer-deps)
cp "$work/package/package-lock.json" package-lock.json
src=$(nix hash file --sri "$work/knip.tgz")
sed -i -E \
  -e "s/^(        version = )\"$old\"/\1\"$new\"/" \
  -e "s|(hash = )\"sha256-[^\"]+\"|\1\"$src\"|" \
  -e "s|(npmDepsHash = )\"sha256-[^\"]+\"|\1\"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"|" flake.nix
deps=$(nix build .#default --accept-flake-config --no-link 2>&1 | grep -oE 'got: +sha256-[A-Za-z0-9+/=]+' | awk '{print $2}' | head -n1)
[ -n "$deps" ] || { echo "could not derive npmDepsHash" >&2; exit 1; }
sed -i -E "s|(npmDepsHash = )\"sha256-[^\"]+\"|\1\"$deps\"|" flake.nix
echo "bumped $old -> $new"
