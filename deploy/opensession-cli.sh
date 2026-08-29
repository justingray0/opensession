#!/usr/bin/env bash
# Operator CLI shim for source checkouts (mirrors install.sh, without curl|bash).
#
# Installed to ~/.opensession/bin/opensession so git credential helpers and
# docs match upstream paths.ts SHIM_PATH. Targets the shared WIP checkout,
# not the live release pointer — `opensession update` mutates git there.
set -euo pipefail

checkout="${OPENSESSION_DEPLOY_CHECKOUT:-${HOME}/opensession}"
cli="${checkout}/scripts/cli.ts"

if [ ! -f "$cli" ]; then
  echo "opensession: missing $cli — clone the checkout first" >&2
  exit 1
fi

bun_wrapper="${HOME}/.local/bin/opensession-bun"
if [ -x "$bun_wrapper" ]; then
  export OPENSESSION_BUN_CWD="$checkout"
  exec "$bun_wrapper" "$cli" "$@"
fi

bun_bin="${OPENSESSION_BUN_BIN:-$(command -v bun 2>/dev/null || true)}"
case "$bun_bin" in
  */opensession-bun|opensession-bun)
    bun_bin="$(command -v bun 2>/dev/null || true)"
    ;;
esac
if [ -z "$bun_bin" ]; then
  mise_bin="$(command -v mise 2>/dev/null || true)"
  if [ -n "$mise_bin" ] && [ -f "${checkout}/package.json" ]; then
    exec "$mise_bin" exec -C "$checkout" -- bun "$cli" "$@"
  fi
  echo "opensession: bun not found — install opensession-bun or enable mise for ${checkout}" >&2
  exit 1
fi

export PATH="$(dirname "$bun_bin"):${HOME}/.local/bin:${HOME}/.local/share/mise/shims:${PATH}"
exec "$bun_bin" "$cli" "$@"
