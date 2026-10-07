app_root := justfile_directory() / ".container"
image := "docker.io/nixos/nix:2.34.4"
name := "harness-config"
source := justfile_directory() / ".e2e"
consumer := justfile_directory() / "tests" / "consumer"

container-start:
    container system stop
    container system start --app-root {{ app_root }} --enable-kernel-install

container-stop:
    container system stop

[private]
copy:
    rm -rf {{ source }}
    mkdir -p {{ source }}
    git ls-files --cached --others --exclude-standard -z | rsync -a --from0 --files-from=- ./ {{ source }}/

up: copy
    container run --detach --rm --name {{ name }} --memory 2G \
      --mount type=bind,source={{ source }},target=/harness-config,readonly \
      --mount type=bind,source={{ source }}/tests/consumer,target=/consumer,readonly \
      --env HOME=/root \
      --env USER=root \
      --env "NIX_CONFIG=experimental-features = nix-command flakes" \
      {{ image }} sleep infinity
    container exec {{ name }} rm /root/.nix-profile

activate config:
    container exec {{ name }} sh -c '"$(nix build --no-link --print-out-paths --no-write-lock-file \
      --override-input harness-config path:/harness-config \
      /consumer#homeConfigurations.{{ config }}.activationPackage)/activate"'

[positional-arguments]
exec *command:
    container exec {{ name }} "$@"

down:
    container stop {{ name }}

[positional-arguments]
test *args:
    uv run pytest "$@"

update-consumer: copy
    container run --rm --memory 2G \
      --mount type=bind,source={{ source }},target=/harness-config,readonly \
      --mount type=bind,source={{ consumer }},target=/consumer \
      --env "NIX_CONFIG=experimental-features = nix-command flakes" \
      {{ image }} nix flake update --flake /consumer
