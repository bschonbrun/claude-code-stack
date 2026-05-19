#!/usr/bin/env bash
# JSON config merger. Preserves user customizations while adding stack content.

merge_json() {
  local source="$1"
  local target="$2"

  # Deep merge: objects are deep-merged, arrays concatenated (deduped).
  # On a scalar conflict the source (stack) value wins, unless it is null.
  local tmp
  tmp="$(mktemp)"

  # NOTE: jq function arguments are call-by-name filters, not values. The
  # args MUST be bound to $-variables up front — otherwise the recursive
  # `deep_merge(a[$k]; b[$k])` re-evaluates `a`/`b` against the reduce
  # accumulator instead of the original inputs, which fails on nested data.
  jq -s '
    def deep_merge(a; b):
      a as $a | b as $b |
      if ($a | type) == "object" and ($b | type) == "object" then
        reduce (($a + $b) | keys[]) as $k ({}; .[$k] = deep_merge($a[$k]; $b[$k]))
      elif ($a | type) == "array" and ($b | type) == "array" then
        ($a + $b) | unique
      elif $b == null then $a
      else $b end;
    deep_merge(.[0]; .[1])
  ' "$target" "$source" > "$tmp"

  mv "$tmp" "$target"
}

append_stack_section() {
  local source="$1"
  local target="$2"

  # Look for stack-managed section marker in target
  local marker="<!-- CLAUDE_CODE_STACK_MANAGED -->"

  if grep -q "$marker" "$target" 2>/dev/null; then
    # Section exists; replace between marker and end-marker
    local end_marker="<!-- /CLAUDE_CODE_STACK_MANAGED -->"
    awk -v source="$source" -v marker="$marker" -v end_marker="$end_marker" '
      BEGIN { in_section = 0 }
      $0 ~ marker { in_section = 1; print; while ((getline line < source) > 0) print line; next }
      $0 ~ end_marker { in_section = 0; print; next }
      !in_section { print }
    ' "$target" > "$target.new"
    mv "$target.new" "$target"
  else
    # Section doesn't exist; append
    {
      echo ""
      echo "$marker"
      cat "$source"
      echo "$end_marker"
    } >> "$target"
  fi
}
