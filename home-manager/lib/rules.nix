{
  lib,
  runCommandLocal,
  yq-go,
  harness,
  src,
}:
let
  renderers = {
    claude-code = ''
      cp "$rule" "$out/"
    '';
    omp = ''
      ${lib.getExe yq-go} --front-matter=process \
        '.condition = ".*" | .scope = [.paths[] | ("tool:edit(" + . + ")", "tool:write(" + . + ")")] | del(.paths)' \
        "$rule" > "$out/$(basename "$rule")"
    '';
  };
in
runCommandLocal "${harness}-rules" { } ''
  mkdir "$out"
  for rule in ${src}/*.md; do
    if ! sed -n '1{/^---$/!q1}; 2,/^---$/p' "$rule" | grep -q '^paths:'; then
      echo "$rule: a rule needs frontmatter with paths:, otherwise it belongs in AGENTS.md" >&2
      exit 1
    fi
    ${renderers.${harness}}
  done
''
