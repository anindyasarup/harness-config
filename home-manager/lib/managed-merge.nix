{
  lib,
  writeShellApplication,
  writeText,
  formats,
  coreutils,
  jq,
  yq-go,
  harness,
  values,
}:
let
  managedKeys = lib.collect lib.isList (
    lib.mapAttrsRecursiveCond (value: value != { }) (path: _: path) values
  );
  managedKeysFile = (formats.json { }).generate "${harness}-managed-keys.json" managedKeys;
  mergers = {
    claude-code = {
      name = "claude-code-set-global-config";
      runtimeInputs = [ jq ];
      merge = ''
        jq --slurp --argjson previous_keys "$previous_keys" --slurpfile settings ${
          (formats.json { }).generate "claude-code-global-config.json" values
        } '((.[0] // {}) | delpaths($previous_keys)) * $settings[0]' "$file" > "$updated"
      '';
    };
    omp = {
      name = "omp-set-settings";
      runtimeInputs = [ yq-go ];
      merge = ''
        PREVIOUS_KEYS="$previous_keys" yq --from-file ${writeText "omp-merge-settings.yq" ''
          with(select(tag == "!!null"); . = {})
          | with(select(tag != "!!map"); error("the root of " + filename + " is not a mapping"))
          | delpaths(env(PREVIOUS_KEYS) - load("${managedKeysFile}")) * load("${
            (formats.yaml { }).generate "omp-settings.yml" values
          }")
        ''} "$file" > "$updated"
      '';
    };
  };
  merger = mergers.${harness};
in
writeShellApplication {
  inherit (merger) name;
  runtimeInputs = [ coreutils ] ++ merger.runtimeInputs;
  text = ''
    file=$1
    record="$file.managed-keys.json"
    mkdir -p "$(dirname "$file")"
    touch "$file"
    previous_keys=$(cat "$record" 2>/dev/null || echo '[]')
    updated=$(mktemp "$file.XXXXXX")
    trap 'rm -f "$updated"' EXIT
    ${merger.merge}
    mv "$updated" "$file"
    updated_record=$(mktemp "$record.XXXXXX")
    cat ${managedKeysFile} > "$updated_record"
    mv "$updated_record" "$record"
  '';
}
