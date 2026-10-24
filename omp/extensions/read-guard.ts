import { homedir } from "node:os";
import path from "node:path";

const home = homedir();
const envFile = /^\.env(?:[.:]|$)/;
const shellWord = /[^\s;|&<>()'"`=]+/g;
const homePrefix = /^(?:~|\$HOME|\$\{HOME\})(?=\/|$)/;
const fileUrlPrefix = /^file:\/\/(?=\/)/i;

const neverDoReads = @neverDoReads@.map((pattern) => ({
  pattern,
  folder: pattern.replace(/^~(?=\/)/, home).replace(/^\/(?=\/)/, "").replace(/\/\*\*$/, ""),
}));

const absolutePath = (cwd, file) => path.resolve(cwd, file.replace(fileUrlPrefix, "").replace(homePrefix, home));

const within = (folder, file) => file === folder || (file.startsWith(folder) && /^[/:]/.test(file.slice(folder.length)));

const repoRoot = (cwd) => {
  const git = Bun.spawnSync(["@git@", "-C", cwd, "rev-parse", "--show-toplevel"]);
  return git.exitCode === 0 ? git.stdout.toString().trim() : cwd;
};

const refusal = (root) => (file) => {
  const secret = neverDoReads.find(({ folder }) => within(folder, file));
  const envOutside = envFile.test(path.basename(file)) && !within(root, file);
  return [
    secret && `Refused: harness-config's rules mark reading ${secret.pattern} as Never do, and ${file} matches it.`,
    envOutside && `Refused: ${file} is a .env file outside the repo at ${root}, and harness-config's rules mark reading it as Never do.`,
  ].find(Boolean);
};

const files = {
  read: ({ input }, cwd) => [absolutePath(cwd, input.path)],
  bash: ({ input }, cwd) =>
    (input.command.match(shellWord) ?? []).map((word) => absolutePath(path.resolve(cwd, input.cwd ?? "."), word)),
};

export default (pi) => {
  pi.on("tool_call", (event, ctx) => {
    const filesOf = files[event.toolName];
    if (!filesOf) return;
    const reason = filesOf(event, ctx.cwd).map(refusal(repoRoot(ctx.cwd))).find(Boolean);
    if (!reason) return;
    return { block: true, reason };
  });
};
