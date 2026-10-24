# network

## Don't ask

- WebSearch, WebFetch
- `curl`, `wget` GET
- `curl localhost`, `curl 127.0.0.1`
- `dig`, `nslookup`, `host`, `ping -c`
- `gh api` GET

## Ask

- `curl -X POST`, `curl -X PUT`, `curl -X PATCH`, `curl -X DELETE`
- `curl -d`, `curl -F`, `curl -T`
- `curl -H "Authorization: ..."`, `curl -u`
- `gh api -X`, `gh api -f`, `gh api -F`, `gh api --input`
- `ssh`, `scp`, `rsync` to a remote host
- `python -m http.server --bind 127.0.0.1`

## Never do

- Send secrets, tokens or `.env` contents in a request
- Pipe a download into a shell or interpreter
- `python -m http.server` without `--bind 127.0.0.1`, `nc -l`
- `ngrok`, `cloudflared tunnel`, `tailscale funnel`
- `nmap`, `nc -z`
- `ssh-copy-id`
- `gh auth login`, `docker login`
- `pnpm publish`, `cargo publish`, `uv publish`, `gh release create`,
  `docker push`
