{
  lib,
  humanizer,
  mattpocock-skills,
}:
let
  mattpocockPlugin = lib.importJSON "${mattpocock-skills}/.claude-plugin/plugin.json";
in
{
  inherit humanizer;
}
// lib.listToAttrs (
  map (
    path: lib.nameValuePair (baseNameOf path) "${mattpocock-skills}/${lib.removePrefix "./" path}"
  ) mattpocockPlugin.skills
)
