{
  lib,
  writeShellApplication,
  coreutils,
  harness,
  paths,
  dirs ? [ ],
  keep ? [ ],
}:
writeShellApplication {
  name = "${harness}-prune";
  runtimeInputs = [ coreutils ];
  text = ''
    config_dir=$1
    paths=(${lib.escapeShellArgs paths})
    dirs=(${lib.escapeShellArgs dirs})
    keep=(${lib.escapeShellArgs keep})

    is_managed() {
      [[ -L $1 && $(readlink "$1") == ${builtins.storeDir}/*-home-manager-files/* ]]
    }

    is_kept() {
      local entry
      for entry in "''${keep[@]}"; do
        [[ $1 == "$config_dir/$entry" ]] && return 0
      done
      return 1
    }

    prune() {
      if [[ -e $1 || -L $1 ]] && ! is_managed "$1" && ! is_kept "$1"; then
        echo "Removing unmanaged $1"
        rm -rf "$1"
      fi
    }

    for path in "''${paths[@]}"; do
      prune "$config_dir/$path"
    done

    shopt -s dotglob nullglob
    for dir in "''${dirs[@]}"; do
      for entry in "$config_dir/$dir"/*; do
        prune "$entry"
      done
    done
  '';
}
