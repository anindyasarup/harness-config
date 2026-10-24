export default (pi) => {
  const call = JSON.parse(process.env.SCRIPTED_TOOL_CALL);
  const server = Bun.serve({
    hostname: "127.0.0.1",
    port: 0,
    fetch: async (request) => {
      const { messages } = await request.json();
      const answered = messages.some((message) => message.role === "tool");
      const delta = answered
        ? { role: "assistant", content: "done" }
        : {
            role: "assistant",
            tool_calls: [
              {
                index: 0,
                id: "call_1",
                type: "function",
                function: { name: call.name, arguments: JSON.stringify(call.arguments) },
              },
            ],
          };
      const chunks = [
        { choices: [{ index: 0, delta, finish_reason: null }] },
        { choices: [{ index: 0, delta: {}, finish_reason: answered ? "stop" : "tool_calls" }] },
      ].map((chunk) => ({ id: "scripted", object: "chat.completion.chunk", created: 0, model: "scripted", ...chunk }));
      return new Response(
        chunks.map((chunk) => JSON.stringify(chunk)).concat("[DONE]").map((data) => `data: ${data}\n\n`).join(""),
        { headers: { "content-type": "text/event-stream" } },
      );
    },
  });
  pi.registerProvider("scripted", {
    baseUrl: `http://127.0.0.1:${server.port}/v1`,
    apiKey: "scripted",
    api: "openai-completions",
    models: [
      {
        id: "scripted",
        name: "scripted",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 100000,
        maxTokens: 1000,
      },
    ],
  });
};
