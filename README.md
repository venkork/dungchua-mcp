# Đúng Chưa? Remote MCP Server (`app.dungchua/dungchua`)

Hosted **Streamable HTTP** Model Context Protocol (MCP) server for Vietnamese tone pitch-contour guides, acoustic DSP recording gate evaluation, and factual product discovery on [Đúng Chưa?](https://dungchua.app).

- **Remote MCP Endpoint:** `https://dungchua.app/api/mcp`
- **Transport:** `streamable-http` (JSON-RPC 2.0 over HTTPS — no local runtime or installation required)
- **Registry ID:** `app.dungchua/dungchua` (`v1.0.0`)
- **Authentication:** None required (public, read-only, `mutations: false`)
- **Publisher:** Dung Chua Operations ([support@dungchua.app](mailto:support@dungchua.app))
- **Documentation:** [https://dungchua.app/mcp](https://dungchua.app/mcp) · [https://dungchua.app/for-ai-agents](https://dungchua.app/for-ai-agents)

---

## Quickstart: Connect in Your MCP Client

No API keys or local dependencies are required. Point your MCP client directly to `https://dungchua.app/api/mcp`.

### 1. Cursor

Copy [`.cursor/mcp.json`](./.cursor/mcp.json) into your project's `.cursor/mcp.json` (or `~/.cursor/mcp.json` globally):

```json
{
  "mcpServers": {
    "dungchua": {
      "type": "http",
      "url": "https://dungchua.app/api/mcp"
    }
  }
}
```

### 2. Claude Code

Add the remote Streamable HTTP server directly from your terminal:

```bash
claude mcp add --transport http dungchua https://dungchua.app/api/mcp
```

### 3. Claude Desktop

- **Option A (Connectors UI):** Open **Settings → Connectors → Add custom connector** and enter `https://dungchua.app/api/mcp`.
- **Option B (`claude_desktop_config.json`):** See [`claude_desktop_config.json`](./claude_desktop_config.json). Keep **only one** entry matching your Claude Desktop version:
  - Direct HTTP (newer clients): `"type": "http", "url": "https://dungchua.app/api/mcp"`
  - Local `mcp-remote` stdio bridge (for clients requiring a local `command`):

```json
{
  "mcpServers": {
    "dungchua": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://dungchua.app/api/mcp"
      ]
    }
  }
}
```

### 4. Windsurf

Add Đúng Chưa? to `~/.codeium/windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "dungchua": {
      "serverUrl": "https://dungchua.app/api/mcp"
    }
  }
}
```

### 5. Antigravity

In Antigravity's MCP configuration (`mcp_config.json`), register the remote Streamable HTTP endpoint:

```json
{
  "mcpServers": {
    "dungchua": {
      "serverUrl": "https://dungchua.app/api/mcp"
    }
  }
}
```

---

## Available MCP Tools

| Tool | Purpose | Required Arguments |
| :--- | :--- | :--- |
| `dungchua_get_tone_guide` | Retrieve acoustic pitch contour (Chao notation), phonation cue, minimal-pair syllable (`ma`, `mà`, `má`, `mả`, `mã`, `mạ`), and practice URL for any of the 6 Northern Vietnamese tones. | `tone` (`"ngang"` \| `"huyen"` \| `"sac"` \| `"hoi"` \| `"nga"` \| `"nang"`) |
| `dungchua_evaluate_recording_gates` | Deterministically evaluate whether a learner audio frame summary passes Đúng Chưa?'s acoustic DSP admission gates (`SNR >= 10 dB`, `clean_voiced_frames >= 25`, `clean_voiced_ratio >= 0.45`) or must return `ABSTAIN_UNCLEAR_RECORDING`. | `snr_db` (number), `clean_voiced_frames` (integer), `clean_voiced_ratio` (number, `0.0` to `1.0`) |

### Tool Example (`dungchua_get_tone_guide`)

```bash
curl -fsS -X POST https://dungchua.app/api/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "dungchua_get_tone_guide",
      "arguments": { "tone": "nga" }
    }
  }'
```

### Tool Example (`dungchua_evaluate_recording_gates`)

```bash
curl -fsS -X POST https://dungchua.app/api/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "dungchua_evaluate_recording_gates",
      "arguments": {
        "snr_db": 14,
        "clean_voiced_frames": 32,
        "clean_voiced_ratio": 0.65
      }
    }
  }'
```

---

## Available MCP Resources

The server implements `resources/list` and `resources/read` across 4 `application/json` resources:

| Resource URI | Name | Description |
| :--- | :--- | :--- |
| `dungchua://product` | `Đúng Chưa? product summary` | Canonical, claim-safe description of Đúng Chưa?. |
| `dungchua://methodology` | `Đúng Chưa? methodology and limits` | Safe 5-step practice loop, quiet-room scoping, and product boundaries. |
| `dungchua://routes` | `Đúng Chưa? canonical routes` | Public product, practice, and discovery URLs. |
| `dungchua://specifications` | `Đúng Chưa? technical and operational specifications` | Measurable DSP admission gates (`10 dB` SNR, `25` clean voiced frames, `0.45` voiced ratio), YIN F0 + semitone DTW engine, glottal phonation checks, and Northern dialect baseline. |

---

## Discovery & Verification Endpoints

- **Streamable HTTP MCP Endpoint:** [`https://dungchua.app/api/mcp`](https://dungchua.app/api/mcp)
- **MCP Discovery Manifest:** [`https://dungchua.app/.well-known/mcp.json`](https://dungchua.app/.well-known/mcp.json)
- **MCP Registry Domain Proof:** [`https://dungchua.app/.well-known/mcp-registry-auth`](https://dungchua.app/.well-known/mcp-registry-auth)
- **A2A Agent Card:** [`https://dungchua.app/.well-known/agent-card.json`](https://dungchua.app/.well-known/agent-card.json)
- **LLM Markdown Summary:** [`https://dungchua.app/llms.txt`](https://dungchua.app/llms.txt)
- **MCP Documentation:** [`https://dungchua.app/mcp`](https://dungchua.app/mcp)

---

## Scope, Safety & Acoustic Boundaries

- **Quiet-Room Practice First:** Signal admission requires `SNR >= 10 dB`, at least `25` clean voiced F0 frames, and `>= 0.45` clean voiced ratio. Audio that fails admission returns `ABSTAIN` rather than fabricated feedback.
- **Controlled Northern Baseline:** Early drills target the Northern Vietnamese (Hanoi) 6-tone system, including glottal constriction checks for `ngã` `[35ˀ]` and `nặng` `[21ˀ]`.
- **No ASR Tone Judging:** Non-tonal ASR transcription is not used as a tone judge. Pitch evaluation uses YIN F0 tracking and semitone-normalized Dynamic Time Warping (DTW).
- **Read-Only Public Surface:** This MCP server exposes no learner recordings, voice biometrics, user accounts, or billing mutations.
- **Product Access:** Free browser preview at [`https://dungchua.app/practice`](https://dungchua.app/practice); Pro plans (`$12/mo`, `$69/yr`, or `$19` 30-day pass) at [`https://dungchua.app/pricing`](https://dungchua.app/pricing).

---

## Verify Live Endpoint

Run the included smoke test against the live endpoint:

```bash
chmod +x examples/verify-mcp.sh
./examples/verify-mcp.sh
```

## License

MIT — see [LICENSE](./LICENSE). Published by **Dung Chua Operations** ([support@dungchua.app](mailto:support@dungchua.app)).
