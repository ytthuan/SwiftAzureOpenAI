#!/usr/bin/env bash
# diff-symbols.sh <before_dir> <after_dir>
# Produces a markdown diff of symbol names (best-effort).
set -euo pipefail

before="${1:-symbolgraph/before}"
after="${2:-symbolgraph/after}"

tmp_before=$(mktemp)
tmp_after=$(mktemp)

collect() {
  dir="$1"
  if compgen -G "$dir/*.json" > /dev/null; then
    for f in "$dir"/*.json; do
      # Extract "names"."title" fields for relevant kinds
      jq -r '
        .symbols[]? |
        select(.kindIdentifier|test("struct|class|enum|protocol|func|var")) |
        .names.title
      ' "$f" || true
    done | sort -u
  fi
}

collect "$before" > "$tmp_before" || true
collect "$after"  > "$tmp_after"  || true

echo "Added symbols:"
comm -13 "$tmp_before" "$tmp_after" | sed 's/^/- /' || echo "- (none)"
echo ""
echo "Removed symbols:"
comm -23 "$tmp_before" "$tmp_after" | sed 's/^/- /' || echo "- (none)"
echo ""
added_count=$(comm -13 "$tmp_before" "$tmp_after" | wc -l | tr -d ' ')
removed_count=$(comm -23 "$tmp_before" "$tmp_after" | wc -l | tr -d ' ')
echo "**Summary:** Added: $added_count  Removed: $removed_count"

# Cleanup
rm -f "$tmp_before" "$tmp_after"