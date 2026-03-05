#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input.json> <output_prefix>" >&2
  exit 1
fi

INPUT_JSON="$1"
PREFIX="$2"
TMP_XBS="${PREFIX}.xbs"
ROUNDTRIP_JSON="${PREFIX}.roundtrip.json"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/json2xbs.sh" "$INPUT_JSON" "$TMP_XBS"
"$SCRIPT_DIR/xbs2json.sh" "$TMP_XBS" "$ROUNDTRIP_JSON"

echo "Roundtrip done:"
echo "- $TMP_XBS"
echo "- $ROUNDTRIP_JSON"
