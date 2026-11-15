#!/usr/bin/env bash
set -euo pipefail

MCP_URL="${DUNGCHUA_MCP_URL:-https://dungchua.app/api/mcp}"

echo "Verifying Đúng Chưa? Remote MCP endpoint: ${MCP_URL}"
echo ""

echo "1) GET endpoint discovery..."
curl -fsS "${MCP_URL}" | head -c 400
echo ""
echo ""

echo "2) JSON-RPC initialize..."
INIT_RESP="$(curl -fsS -X POST "${MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-03-26",
      "capabilities": {},
      "clientInfo": { "name": "dungchua-mcp-verify", "version": "1.0.0" }
    }
  }')"
echo "${INIT_RESP}" | head -c 400
echo ""
echo ""

echo "3) JSON-RPC tools/list..."
TOOLS_RESP="$(curl -fsS -X POST "${MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}')"
TOOLS_RESP_JSON="${TOOLS_RESP}" python3 - <<'PY'
import json, os, sys
data = json.loads(os.environ["TOOLS_RESP_JSON"])
tools = data.get("result", {}).get("tools", [])
names = [t.get("name") for t in tools]
print("Tools:", names)
for required in ("dungchua_get_tone_guide", "dungchua_evaluate_recording_gates"):
    if required not in names:
        print(f"Missing expected tool: {required}", file=sys.stderr)
        sys.exit(1)
PY
echo ""

echo "4) JSON-RPC resources/list..."
RESOURCES_RESP="$(curl -fsS -X POST "${MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"resources/list","params":{}}')"
RESOURCES_RESP_JSON="${RESOURCES_RESP}" python3 - <<'PY'
import json, os, sys
data = json.loads(os.environ["RESOURCES_RESP_JSON"])
uris = [r.get("uri") for r in data.get("result", {}).get("resources", [])]
print("Resources:", uris)
for required in ("dungchua://product", "dungchua://methodology", "dungchua://routes", "dungchua://specifications"):
    if required not in uris:
        print(f"Missing expected resource: {required}", file=sys.stderr)
        sys.exit(1)
PY
echo ""

echo "5) Smoke test: dungchua_get_tone_guide (nga)..."
TONE_RESP="$(curl -fsS -X POST "${MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"dungchua_get_tone_guide","arguments":{"tone":"nga"}}}')"
TONE_RESP_JSON="${TONE_RESP}" python3 - <<'PY'
import json, os, sys
data = json.loads(os.environ["TONE_RESP_JSON"])
payload = json.loads(data["result"]["content"][0]["text"])
assert payload["tone"] == "nga", payload
assert payload["syllable"] == "mã", payload
print("  syllable:", payload["syllable"], "| contour:", payload["contour"])
PY
echo ""

echo "6) Smoke test: dungchua_evaluate_recording_gates (admit + abstain)..."
ADMIT_RESP="$(curl -fsS -X POST "${MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"dungchua_evaluate_recording_gates","arguments":{"snr_db":14,"clean_voiced_frames":32,"clean_voiced_ratio":0.65}}}')"
ABSTAIN_RESP="$(curl -fsS -X POST "${MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"dungchua_evaluate_recording_gates","arguments":{"snr_db":6,"clean_voiced_frames":18,"clean_voiced_ratio":0.30}}}')"
ADMIT_JSON="${ADMIT_RESP}" ABSTAIN_JSON="${ABSTAIN_RESP}" python3 - <<'PY'
import json, os
admit = json.loads(json.loads(os.environ["ADMIT_JSON"])["result"]["content"][0]["text"])
abstain = json.loads(json.loads(os.environ["ABSTAIN_JSON"])["result"]["content"][0]["text"])
assert admit["verdict"] == "ADMITTED_FOR_F0_SCORING" and admit["admitted"] is True, admit
assert abstain["verdict"] == "ABSTAIN_UNCLEAR_RECORDING" and abstain["admitted"] is False, abstain
print("  admit:", admit["verdict"], "| abstain:", abstain["verdict"])
PY
echo ""

echo "Verification completed."
