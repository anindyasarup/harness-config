app_root := justfile_directory() / ".container"
image := "docker.io/nixos/nix:2.34.4"
name := "harness-config"
source := justfile_directory() / ".e2e"
consumer := justfile_directory() / "tests" / "consumer"
interface_dir := justfile_directory() / ".interface"

[doc('list recipes')]
default:
    @just --list

[doc('restart the container services with images kept in .container')]
[group('services')]
container-start:
    container system stop
    container system start --app-root {{ app_root }} --enable-kernel-install

[doc('stop the container services')]
[group('services')]
container-stop:
    container system stop

[doc('start the test container with a clean copy of the repo mounted')]
[group('in-container')]
up: copy
    container run --detach --rm --name {{ name }} --memory 2G \
      --mount type=bind,source={{ source }},target=/harness-config,readonly \
      --mount type=bind,source={{ source }}/tests/consumer,target=/consumer,readonly \
      --env HOME=/root \
      --env USER=root \
      --env "NIX_CONFIG=experimental-features = nix-command flakes" \
      {{ image }} sleep infinity
    container exec {{ name }} rm /root/.nix-profile

[doc('build a consumer homeConfiguration inside the container without activating it')]
[group('in-container')]
build config:
    container exec {{ name }} nix build --no-link --no-write-lock-file \
      --override-input harness-config path:/harness-config \
      /consumer#homeConfigurations.{{ config }}.activationPackage

[doc('build and activate a consumer homeConfiguration inside the container')]
[group('in-container')]
activate config:
    container exec {{ name }} sh -c '"$(nix build --no-link --print-out-paths --no-write-lock-file \
      --override-input harness-config path:/harness-config \
      /consumer#homeConfigurations.{{ config }}.activationPackage)/activate"'

[doc('run a command inside the container')]
[group('in-container')]
[positional-arguments]
exec *command:
    container exec {{ name }} "$@"

[doc('stop the test container')]
[group('in-container')]
down:
    container stop {{ name }}

[doc('run the end-to-end tests, passing any arguments to pytest')]
[group('tests')]
[positional-arguments]
test *args:
    uv run pytest "$@"

[doc('update tests/consumer/flake.lock from inside a container')]
[group('tests')]
update-consumer: copy
    container run --rm --memory 2G \
      --mount type=bind,source={{ source }},target=/harness-config,readonly \
      --mount type=bind,source={{ consumer }},target=/consumer \
      --env "NIX_CONFIG=experimental-features = nix-command flakes" \
      {{ image }} nix flake update --flake /consumer

[doc('print the flake outputs, harness options and replaced files that consumers depend on at a git ref')]
[group('release')]
interface ref:
    rm -rf {{ interface_dir }}/{{ ref }}
    mkdir -p {{ interface_dir }}/{{ ref }}
    git archive {{ ref }} | tar -x -C {{ interface_dir }}/{{ ref }}
    container run --rm --memory 2G \
      --mount type=bind,source={{ interface_dir }}/{{ ref }},target=/harness-config,readonly \
      --mount type=bind,source={{ consumer }},target=/consumer,readonly \
      --env "NIX_CONFIG=experimental-features = nix-command flakes" \
      {{ image }} nix eval --raw --no-write-lock-file \
      --override-input harness-config path:/harness-config /consumer#interface

[doc('show how the interface changed between a git ref and HEAD')]
[group('release')]
interface-diff ref:
    mkdir -p {{ interface_dir }}
    just interface {{ ref }} > {{ interface_dir }}/{{ ref }}.txt
    just interface HEAD > {{ interface_dir }}/HEAD.txt
    diff {{ interface_dir }}/{{ ref }}.txt {{ interface_dir }}/HEAD.txt || [ $? -eq 1 ]

[doc('copy the tracked and unignored files into .e2e')]
[private]
copy:
    rm -rf {{ source }}
    mkdir -p {{ source }}
    git ls-files --cached --others --exclude-standard -z | rsync -a --from0 --files-from=- ./ {{ source }}/
