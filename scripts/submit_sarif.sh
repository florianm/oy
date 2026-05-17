set -euo pipefail

OWNER="florianm"
REPO="SETME"
BRANCH="main"
REF="refs/heads/$BRANCH"
SARIF_PATH="/workspaces/oy/src/$OWNER/$REPO/REPORT.sarif"

if [[ ! -f "$SARIF_PATH" ]]; then
  echo "SARIF file not found: $SARIF_PATH" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated. Run: gh auth login" >&2
  exit 1
fi

COMMIT_SHA="$(git ls-remote "https://github.com/$OWNER/$REPO.git" "$REF" | awk '{print $1}')"

if [[ -z "$COMMIT_SHA" ]]; then
  echo "Could not resolve commit SHA for $OWNER/$REPO $REF" >&2
  exit 1
fi

SARIF_B64="$(gzip -c "$SARIF_PATH" | base64 -w0)"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "Uploading SARIF for $OWNER/$REPO at $REF ($COMMIT_SHA)..."

RESPONSE="$(
  jq -n \
    --arg commit_sha "$COMMIT_SHA" \
    --arg ref "$REF" \
    --arg sarif "$SARIF_B64" \
    --arg tool_name "oy markdown-to-sarif" \
    --arg checkout_uri "file:///github/workspace" \
    --arg started_at "$STARTED_AT" \
    '{
      commit_sha: $commit_sha,
      ref: $ref,
      sarif: $sarif,
      tool_name: $tool_name,
      checkout_uri: $checkout_uri,
      started_at: $started_at,
      validate: true
    }' \
  | gh api \
      --method POST \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "repos/$OWNER/$REPO/code-scanning/sarifs" \
      --input -
)"

echo "$RESPONSE" | jq .

SARIF_ID="$(echo "$RESPONSE" | jq -r '.id')"

if [[ -z "$SARIF_ID" || "$SARIF_ID" == "null" ]]; then
  echo "Upload did not return a sarif id." >&2
  exit 1
fi

echo "Polling upload status for SARIF ID: $SARIF_ID"

for attempt in $(seq 1 30); do
  STATUS_JSON="$(
    gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "repos/$OWNER/$REPO/code-scanning/sarifs/$SARIF_ID"
  )"

  STATUS="$(echo "$STATUS_JSON" | jq -r '.processing_status')"
  ANALYSES_URL="$(echo "$STATUS_JSON" | jq -r '.analyses_url // empty')"
  ERRORS="$(echo "$STATUS_JSON" | jq -r '.errors // empty')"

  echo "Attempt $attempt: status=$STATUS"

  if [[ "$STATUS" == "complete" ]]; then
    echo
    echo "Upload complete."
    if [[ -n "$ANALYSES_URL" ]]; then
      echo "Analyses URL: $ANALYSES_URL"
    fi
    echo "Security tab: https://github.com/$OWNER/$REPO/security/code-scanning"
    exit 0
  fi

  if [[ "$STATUS" == "failed" || "$STATUS" == "error" ]]; then
    echo "Upload failed." >&2
    echo "$STATUS_JSON" | jq .
    exit 1
  fi

  sleep 5
done

echo "Timed out waiting for SARIF processing." >&2
exit 1
