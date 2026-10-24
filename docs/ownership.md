# Ownership

**WARNING:** once on, harness-config owns most of each harness's config
folder. [ADR 0002](adr/0002-omp-config-ownership.md) explains why omp's config
is merged instead of linked.

Everything in a harness's folder falls into one of four buckets:

| Bucket           | claude-code                                                                                | omp                                                                                                     |
| ---------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Linked, replaced | `settings.json`, `keybindings.json`, `CLAUDE.md`, `rules/`, `hooks/`, declared skills      | `AGENTS.md`, `rules/`, `hooks/`, `keybindings.yml`, `extensions/harness-read-guard.ts`, declared skills |
| Deleted          | Skills it doesn't declare except `skills/synced`, `agents/`, `commands/`, `output-styles/` | Skills it doesn't declare, `agents/`, `commands/`                                                       |
| Merged           | `.claude.json`: sets the keys from `claude-code/global-config.nix`, keeps the rest         | `config.yml`: sets the keys from `omp/settings.nix`, keeps the rest                                     |
| Left alone       | MCP servers, states and secrets (sessions, history, cache etc)                             | `mcp.json`, the rest of `extensions/`, sessions                                                         |

Linked files are read-only, so claude-code can't change its own
`settings.json`. harness-config never tracks states or secrets.

## claude-code

| Heads up      | Details                                                                                    |
| ------------- | ------------------------------------------------------------------------------------------ |
| Harnesses     | Never installed from here. I install claude-code myself.                                   |
| Removed       | `.claude.json` keys a release stops setting, listed in `.claude.json.managed-keys.json`    |
| Settings      | `programs.claude-code.mutableSettings` has to stay `false`                                 |
| Version check | Only runs when claude-code comes from `programs.claude-code.package`, warns otherwise      |
| MCP servers   | Not managed. I add them with `claude mcp add`, and claude-code keeps them                  |

harness-config sets up `~/.claude`. If claude-code's config lives somewhere
else, I set `programs.claude-code.configDir` to that path.

## omp

Like claude-code, omp is never installed from here.

Activation deletes every entry in `skills/` that it didn't link, including
skills I added by hand. Those can live in `~/.agents/skills` instead: omp reads
it too, and harness-config leaves it alone. Any `rules/` or `hooks/` already
there is deleted before harness-config links its own, so rules and hooks I
wrote by hand go too. In `extensions/`, only `harness-read-guard.ts` is
replaced, and the rest stays.

omp rewrites `config.yml` while it runs, so it stays a regular file instead of
a link. Each activation sets the managed keys again, keeps everything else
(such as my theme or onboarding answers), and creates the file if it's
missing. If `config.yml` isn't valid YAML, or its root isn't a mapping,
activation fails and leaves the file alone. omp's onboarding wizard still runs
on first launch.

omp's agent folder is `~/.omp/agent`. If it lives somewhere else, I set
`home.sessionVariables.PI_CODING_AGENT_DIR` to that path.

**WARNING:** plain pi reads `PI_CODING_AGENT_DIR` too, and home-manager's
`programs.pi-coding-agent.configDir` can set it. If it points at pi's folder,
omp and harness-config both write there.

## Managed keys

Next to each merged file, activation writes a record of the key paths it set:
`.claude.json.managed-keys.json` for claude-code and
`config.yml.managed-keys.json` for omp. The record is a JSON list of paths,
such as `[["defaultToAgentsView"]]`. On the next activation, any key in that
list that harness-config no longer sets is removed from the file, so the
harness falls back to its own default. Keys I set myself are never removed,
and the first activation, with no record yet, removes nothing.

Turning off `harness.claude-code.enable` or `harness.omp.enable` skips this
step, so the managed keys stay in place. To clear them, I remove each path
listed in the record and then the record itself.

For claude-code, with jq:

```sh
jq --slurpfile keys ~/.claude.json.managed-keys.json 'delpaths($keys[0])' \
  ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
rm ~/.claude.json.managed-keys.json
```

If `CLAUDE_CONFIG_DIR` is set, both files live there instead of in `~`.

For omp, with yq (`yq-go`):

```sh
yq -i "delpaths($(cat ~/.omp/agent/config.yml.managed-keys.json))" \
  ~/.omp/agent/config.yml
rm ~/.omp/agent/config.yml.managed-keys.json
```

If `PI_CODING_AGENT_DIR` is set, both files live there instead.
