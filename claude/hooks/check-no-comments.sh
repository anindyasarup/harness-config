#!/run/current-system/sw/bin/bash
# PostToolUse hook (Write|Edit|MultiEdit|NotebookEdit): blocks with a corrective
# reason when a write introduces a comment. Comments explaining WHAT code does
# are redundant with well-named identifiers; non-obvious WHY context belongs in
# an ADR (docs/adr/) or the project's CLAUDE.md, not inline.
#
# Only text the tool call actually added is checked, so pre-existing comments
# elsewhere in the file can't wedge every later edit into a block loop.
# Load-bearing directive comments (shebangs, shellcheck/noqa/eslint pragmas,
# build tags, SPDX headers) are exempt, as are non-code file types and
# vendored/generated paths. Detection is grep, not a language parser, so it can
# false-positive (e.g. a string containing a literal '#'); the small blast
# radius of a wrong block (edit the file, retry) is preferred over silently
# missing real comments. Set CLAUDE_ALLOW_COMMENTS=1 to disable.

[ -n "$CLAUDE_ALLOW_COMMENTS" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

# One jq pass yields both the target path and the added text. The "END" line is
# a sentinel absorbing the trailing-newline strip that command substitution
# performs, so the payload keeps its own trailing newlines. Without it a
# newline-only payload would collapse to empty and spuriously trigger the
# whole-file fallback below.
nl=$'\n'
parsed=$(jq -r '
  ( .tool_response.filePath // .tool_input.file_path // .tool_input.notebook_path // "" ),
  ( .tool_input // {}
    | [ .content, .new_string, .new_source, (.edits[]?.new_string) ]
    | map(select(type == "string")) | join("\n") ),
  "END"
' 2>/dev/null)
parsed=${parsed%"${nl}END"}
f=${parsed%%"$nl"*}
added=${parsed#"$f"}
added=${added#"$nl"}

[ -f "$f" ] || exit 0

case "$f" in
  */node_modules/*|*/vendor/*|*/dist/*|*/build/*|*/.git/*|*/target/*|*/.venv/*|*/venv/*|\
  */.direnv/*|*/result/*|*/.next/*|*/.terraform/*|*/Pods/*|*/__pycache__/*|\
  */generated/*|*.min.js|*.min.css|*.pb.go|*_pb2.py|*.g.dart|*/.claude/hooks/*)
    exit 0 ;;
esac

# A block comment's body and closer carry no opener, so a payload adding only
# the middle of a /* ... */ run would otherwise pass clean. Assembled in named
# pieces like the exempt regex below; the concatenation is one flat alternation.
# The [^{,] guard keeps the body branch off CSS's universal selector
# ('* { ... }', '*, *::before'), and requiring whitespace after the star keeps
# it off C pointer statements ('*p = 1;').
block_close='\*/'
block_body='^[[:space:]]*\*([[:space:]]+[^{,]|\*|$)'

# Extensions turn up in any case in the wild ('.R', '.C', '.PY'), so dispatch on
# a lowercased copy. $f itself stays intact for the path tests and file reads,
# where case is significant.
fl=${f,,}

case "$fl" in
  *.nix|*.sh|*.bash|*.zsh|*.fish|*.nu|*.py|*.rb|*.pl|*.ex|*.exs|*.r|*.jl|*.tcl|\
  *.yaml|*.yml|*.toml|*.tf|*.tfvars|*.hcl|*.conf|*.cfg|*.ini|*.envrc|*.gitconfig|\
  */justfile|*/.justfile|*/makefile|*/gnumakefile|*/dockerfile|*.dockerfile|\
  */cmakelists.txt|*.cmake|*/pkgbuild|*.ipynb)
    pattern='(^|[[:space:]])#' ;;
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.mts|*.cts|*.go|*.rs|*.c|*.h|*.cc|*.cpp|*.cxx|\
  *.hpp|*.hh|*.m|*.mm|*.java|*.kt|*.kts|*.swift|*.cs|*.scss|*.less|*.php|*.scala|\
  *.dart|*.groovy|*.gradle|*.zig|*.proto|*.jsonc|*.json5|*.glsl|*.v|*.sv)
    pattern="(^|[^:])//|/\*|$block_close|$block_body" ;;
  *.css)
    pattern="/\*|$block_close|$block_body" ;;
  *.lua|*.sql|*.hs|*.elm|*.adb|*.ads)
    pattern='(^|[[:space:]])--' ;;
  *.html|*.htm|*.xml|*.vue|*.svelte)
    pattern='<!--|-->' ;;
  *)
    # Extensionless files are checked only when a shebang marks them as scripts.
    [[ $fl == *.* ]] && exit 0
    IFS= read -r -n 2 magic < "$f" 2>/dev/null
    [ "$magic" = '#!' ] || exit 0
    pattern='(^|[[:space:]])#' ;;
esac

# Generated files are exempt. Matched line by line with builtins rather than
# head|grep, so the common path stays fork-free.
generated='Code generated|@generated|DO NOT EDIT'
mapfile -t -n 5 head5 < "$f"
for l in "${head5[@]}"; do [[ $l =~ $generated ]] && exit 0; done

# Directives the toolchain reads: deleting them changes behaviour or breaks builds.
# Each alternative must be specific enough that ordinary prose can't match it:
# a bare word here silently exempts every comment containing it. Assembled in
# ecosystem-sized chunks so a diff shows which one changed; the concatenation is
# one flat alternation, matched by a single grep.
exempt='^[[:space:]]*#!|#\{'
exempt="$exempt|shellcheck |noqa|type:[[:space:]]*ignore|pragma[:[:space:]]"
exempt="$exempt|pylint:|ruff:|mypy:|flake8:|isort:|fmt:[[:space:]]*(off|on|skip)"
exempt="$exempt|coding[:=]|frozen_string_literal|rubocop:"
exempt="$exempt|yamllint|nosec|nolint|NOLINT|trunk-ignore|checkov:|tflint-ignore"
exempt="$exempt|renovate:|dependabot"
exempt="$exempt|go:(build|generate|embed|linkname|noinline|cgo)|\+build|#cgo[[:space:]]"
exempt="$exempt|eslint-(disable|enable|env)|eslint[[:space:]]+[a-z@][a-z0-9@/_-]*:"
exempt="$exempt|@ts-|@flow|@jsx|prettier-ignore|biome-ignore|deno-lint-ignore"
exempt="$exempt|(jshint|jslint)[[:space:]]+[a-z]+:|/\*[[:space:]]*globals?[[:space:]]"
exempt="$exempt|istanbul ignore|c8 ignore|v8 ignore"
exempt="$exempt|swiftlint:|clang-format|sourceMappingURL|SPDX-License-Identifier"
exempt="$exempt|<!--[[:space:]]*(markdownlint|prettier)"

# No parsable payload (unknown tool shape): fall back to scanning the whole
# file. A notebook on disk is JSON, not source, so there is nothing to scan.
if [ -z "$added" ]; then
  case "$fl" in *.ipynb) exit 0 ;; esac
  added=$(cat "$f")
fi

offenders=$(grep -E "$pattern" <<< "$added" | grep -vE "$exempt")
[ -n "$offenders" ] || exit 0

# Offender text comes from the payload, so line numbers have to be looked up in
# the file. One grep resolves all of them; the loop below is pure builtins.
n=$(grep -c '' <<< "$offenders")
top=$(head -5 <<< "$offenders")
hits=$(grep -n -F -x -f <(printf '%s\n' "$top") "$f" 2>/dev/null)

report=""
while IFS= read -r l; do
  num=
  while IFS= read -r h; do
    [ "${h#*:}" = "$l" ] && { num=${h%%:*}; break; }
  done <<< "$hits"
  trimmed=${l#"${l%%[![:space:]]*}"}
  report="${report}  ${num:+line ${num}: }${trimmed}"$'\n'
done <<< "$top"

[ "$n" -gt 5 ] && report="${report}  ... and $((n - 5)) more"$'\n'

jq -n --arg f "$f" --arg r "$report" --arg n "$n" \
  '{decision:"block", reason: ($n + " comment(s) introduced in " + $f + ":\n" + $r + "\nMove non-obvious \"why\" context to docs/adr/ (design decisions) or CLAUDE.md (standing constraints); otherwise delete it. Load-bearing directives (shebang, shellcheck, eslint, build tags) are already exempt, so these are not that.")}'
