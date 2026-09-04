#!/usr/bin/env bash
# Convert captured PNGs to the AVIF files the page references.
# The page contract: AVIF, explicit width/height in the markup, loading and
# decoding attributes, and real alt text. This script handles the format; the
# markup is on you.
set -euo pipefail

IN="${1:-.tmp/capture}"
OUT="${2:-assets}"

command -v avifenc >/dev/null 2>&1 || {
  echo "avifenc not found. brew install libavif" >&2
  exit 1
}

for png in "$IN"/*.png; do
  [ -e "$png" ] || { echo "no PNGs in $IN" >&2; exit 1; }
  base="$(basename "$png" .png)"
  avifenc --min 20 --max 34 --speed 4 "$png" "$OUT/kanna-$base.avif"
  # print the intrinsic size so the markup can carry matching width/height
  sips -g pixelWidth -g pixelHeight "$png" | tail -2 | tr -d ' \n'
  echo "  -> $OUT/kanna-$base.avif"
done
