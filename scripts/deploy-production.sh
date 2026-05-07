#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE_BIN="${NODE_BIN:-/Users/elicipriani/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node}"
VERCEL_JS="$ROOT/.codex-tools/vercel-cli/node_modules/vercel/dist/vc.js"
VERCEL_HOME="${VERCEL_HOME:-/private/tmp/por-elisa-vercel-home}"
SITE_URL="${SITE_URL:-https://porelisa.com}"

if [ ! -x "$NODE_BIN" ]; then
  NODE_BIN="$(command -v node || true)"
fi

if [ -z "$NODE_BIN" ] || [ ! -x "$NODE_BIN" ]; then
  echo "Node.js is required for the Vercel CLI." >&2
  exit 1
fi

if [ ! -f "$VERCEL_JS" ]; then
  echo "Vercel CLI is missing at $VERCEL_JS." >&2
  exit 1
fi

if [ ! -d "$ROOT/.vercel" ]; then
  echo "This project is not linked to Vercel. Run vercel link first." >&2
  exit 1
fi

DEPLOY_DIR="$(mktemp -d /private/tmp/por-elisa-vercel-deploy.XXXXXX)"
cleanup() {
  rm -rf "$DEPLOY_DIR"
}
trap cleanup EXIT

(
  cd "$ROOT"
  git archive --format=tar HEAD index.html assets projects | tar -x -C "$DEPLOY_DIR"
)

cp -R "$ROOT/.vercel" "$DEPLOY_DIR/.vercel"

(
  cd "$DEPLOY_DIR"
  HOME="$VERCEL_HOME" "$NODE_BIN" "$VERCEL_JS" --prod --yes
)

curl -fsSI "$SITE_URL" >/dev/null
curl -fsSI "$SITE_URL/assets/css/styles.css" >/dev/null
curl -fsSI "$SITE_URL/assets/images/home/elisa-bio.png" >/dev/null

echo "Production is live and verified at $SITE_URL"
