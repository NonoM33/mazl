#!/bin/sh
# Reconstruit assets/duo_tutorial/three.min.js depuis la copie figée de
# three.js r170 (vendor/three.module.min.js, licence MIT dans
# vendor/LICENSE-three.txt). Aucun réseau : bun élague et assemble en un script
# classique, que WKWebView charge depuis file:// (un module ES y est refusé).
#
#   cd mobile && sh tool/duo_tutorial/build_three.sh
set -eu
cd "$(dirname "$0")"
out=../../assets/duo_tutorial
tmp=$(mktemp -d)
bun build vendor/entry.js --format=iife --minify --outfile="$tmp/three.js" >/dev/null
{
  printf '/*! three.js r170 (https://threejs.org), MIT. Copyright 2010-2024 three.js authors. Voir LICENSE-three.txt. */\n'
  cat "$tmp/three.js"
} > "$out/three.min.js"
cp vendor/LICENSE-three.txt "$out/LICENSE-three.txt"
rm -rf "$tmp"
wc -c "$out/three.min.js"
