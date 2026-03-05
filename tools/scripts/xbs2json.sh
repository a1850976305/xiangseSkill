#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input.xbs> <output.json>" >&2
  exit 1
fi

INPUT_XBS="$1"
OUTPUT_JSON="$2"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
XBSREBUILD_ROOT="${XBSREBUILD_ROOT:-/Users/mantou/Documents/idea/3.2/xbsrebuild}"

mkdir -p "$PROJECT_ROOT/.cache/gocache" "$PROJECT_ROOT/.cache/gomodcache"

cd "$XBSREBUILD_ROOT"
GOPROXY="${GOPROXY:-https://goproxy.cn,direct}" \
GOSUMDB="${GOSUMDB:-sum.golang.google.cn}" \
GOCACHE="$PROJECT_ROOT/.cache/gocache" \
GOMODCACHE="$PROJECT_ROOT/.cache/gomodcache" \
go run . xbs2json -i "$INPUT_XBS" -o "$OUTPUT_JSON"

echo "OK: $OUTPUT_JSON"
