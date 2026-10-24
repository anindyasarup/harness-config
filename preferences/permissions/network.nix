let
  commands =
    verdict:
    map (command: {
      inherit verdict command;
    });
  prose =
    verdict:
    map (prose: {
      inherit verdict prose;
    });
in
commands "dont-ask" [
  "dig"
  "nslookup"
  "host"
  "ping -c"
]
++ prose "dont-ask" [
  "Searching the web with WebSearch and fetching pages with WebFetch."
  "GET requests with `curl` or `wget` that send no credentials."
  "Requests with `curl` to `localhost` or `127.0.0.1`, on any port or path."
  "GET requests with `gh api`."
]
++ commands "ask" [
  "curl -X POST"
  "curl -X PUT"
  "curl -X PATCH"
  "curl -X DELETE"
  "curl -d"
  "curl -F"
  "curl -T"
  "curl -u"
  "gh api -X"
  "gh api -f"
  "gh api -F"
  "gh api --input"
  "python -m http.server --bind 127.0.0.1"
]
++ prose "ask" [
  "Requests with `curl` that send an `Authorization` header."
  "`ssh`, `scp` or `rsync` to a remote host."
]
++ prose "never-do" [
  "Sending secrets, tokens or `.env` contents in a request."
  "Piping a download into a shell or interpreter."
  "Starting `python -m http.server` without `--bind 127.0.0.1`."
]
++ commands "never-do" [
  "nc -l"
  "ngrok"
  "cloudflared tunnel"
  "tailscale funnel"
  "nmap"
  "nc -z"
  "ssh-copy-id"
  "gh auth login"
  "docker login"
  "pnpm publish"
  "cargo publish"
  "uv publish"
  "gh release create"
  "docker push"
]
