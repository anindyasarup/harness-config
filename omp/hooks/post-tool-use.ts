const addedLine = /^\+\d+\|/;

const addedText = (diff) =>
  diff
    .split("\n")
    .filter((line) => addedLine.test(line))
    .map((line) => line.replace(addedLine, ""))
    .join("\n");

const changes = {
  write: ({ input, details }) => [{ path: details.resolvedPath, added: input.content ?? "" }],
  edit: ({ details }) =>
    (details.perFileResults ?? [details]).map(({ path, diff }) => ({ path, added: addedText(diff ?? "") })),
};

const check = async ({ path, added }) => {
  const runner = Bun.spawn(["@runner@", path], { stdin: new Blob([added]), stdout: "pipe" });
  return new Response(runner.stdout).text();
};

export default (pi) => {
  pi.on("tool_result", async (event) => {
    const changesOf = changes[event.toolName];
    if (!changesOf || event.isError) return;
    const reasons = await Promise.all(changesOf(event).map(check));
    const reason = reasons.join("").trimEnd();
    if (reason === "") return;
    return { isError: true, content: event.content.concat({ type: "text", text: reason }) };
  });
};
