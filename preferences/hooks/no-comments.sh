#!/usr/bin/env bash

[ -n "$ALLOW_COMMENTS" ] && exit 0

f=$1
added=$(cat)

[ -f "$f" ] || exit 0

case "$f" in
  */node_modules/*|*/vendor/*|*/dist/*|*/build/*|*/.git/*|*/target/*|*/.venv/*|*/venv/*|\
  */.direnv/*|*/result/*|*/.next/*|*/.terraform/*|*/Pods/*|*/__pycache__/*|\
  */generated/*|*.min.js|*.min.css|*.pb.go|*_pb2.py|*.g.dart)
    exit 0 ;;
esac

block_close='\*/'
block_body='^[[:space:]]*\*([[:space:]]+[^{,]|\*|$)'

fl=${f,,}

case "$fl" in
  *.nix|*.sh|*.bash|*.zsh|*.fish|*.nu|*.py|*.rb|*.pl|*.ex|*.exs|*.r|*.jl|*.tcl|\
  *.yaml|*.yml|*.toml|*.tf|*.tfvars|*.hcl|*.conf|*.cfg|*.ini|*.envrc|*.gitconfig|\
  */justfile|*/.justfile|*/makefile|*/gnumakefile|*/dockerfile|*.dockerfile|\
  */cmakelists.txt|*.cmake|*/pkgbuild|*.ipynb)
    pattern='(^|[[:space:]])#([^{]|$)' ;;
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
    [[ ${fl##*/} == *.* ]] && exit 0
    IFS= read -r -n 2 magic < "$f" 2>/dev/null
    [ "$magic" = '#!' ] || exit 0
    pattern='(^|[[:space:]])#([^{]|$)' ;;
esac

exempt='^[[:space:]]*#!'
exempt="$exempt|shellcheck |noqa|type:[[:space:]]*ignore|pragma[:[:space:]]"
exempt="$exempt|pylint:|ruff:|mypy:|flake8:|isort:|fmt:[[:space:]]*(off|on|skip)"
exempt="$exempt|coding[:=]|frozen_string_literal|rubocop:"
exempt="$exempt|yamllint[[:space:]]+(disable|enable)"
exempt="$exempt|nosec|nolint|NOLINT|trunk-ignore|checkov:|tflint-ignore"
exempt="$exempt|renovate:|dependabot"
exempt="$exempt|go:(build|generate|embed|linkname|noinline|cgo)|\+build|#cgo[[:space:]]"
exempt="$exempt|eslint-(disable|enable|env)|eslint[[:space:]]+[a-z@][a-z0-9@/_-]*:"
exempt="$exempt|@ts-|@flow|@jsx|prettier-ignore|biome-ignore|deno-lint-ignore"
exempt="$exempt|(jshint|jslint)[[:space:]]+[a-z]+:|/\*[[:space:]]*globals?[[:space:]]"
exempt="$exempt|istanbul ignore|c8 ignore|v8 ignore"
exempt="$exempt|swiftlint:|clang-format[[:space:]]+(on|off)"
exempt="$exempt|sourceMappingURL|SPDX-License-Identifier"
exempt="$exempt|<!--[[:space:]]*(markdownlint|prettier)"

offenders=$(grep -E "$pattern" <<< "$added" | grep -vE "$exempt")
[ -n "$offenders" ] || exit 0

generated='Code generated|@generated|DO NOT EDIT'
mapfile -t -n 5 head5 < "$f"
for l in "${head5[@]}"; do [[ $l =~ $generated ]] && exit 0; done

n=$(grep -c '' <<< "$offenders")
top=$(head -5 <<< "$offenders")
hits=$(grep -n -F -x -f <(printf '%s\n' "$top") "$f" 2>/dev/null)

report=""
while IFS= read -r l; do
  num=''
  seen=0
  while IFS= read -r h; do
    [ "${h#*:}" = "$l" ] && { num=${h%%:*}; seen=$((seen + 1)); }
  done <<< "$hits"
  [ "$seen" -eq 1 ] || num=
  trimmed=${l#"${l%%[![:space:]]*}"}
  report="${report}  ${num:+line ${num}: }${trimmed}"$'\n'
done <<< "$top"

[ "$n" -gt 5 ] && report="${report}  ... and $((n - 5)) more"$'\n'

printf '%s comment(s) introduced in %s:\n%s\n%s\n' "$n" "$f" "$report" \
  'Move non-obvious "why" context to docs/adr/ (design decisions) or the project'\''s AGENTS.md (standing constraints); otherwise delete it. Load-bearing directives (shebang, shellcheck, eslint, build tags) are already exempt, so these are not that.'
