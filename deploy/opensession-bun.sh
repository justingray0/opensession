#!/usr/bin/env bash
# Run Bun with mise against the live release by default, or an explicit cwd.
#
# Systemd units and run-host children invoke this wrapper so packageManager
# comes from the pinned release tree. Release preparation passes
# OPENSESSION_BUN_CWD to target a detached worktree instead.
set -euo pipefail

release="${OPENSESSION_RELEASE_ROOT:-${HOME}/.opensession/deploy/current}"
cwd="${OPENSESSION_BUN_CWD:-$release}"

mise_bin="$(command -v mise 2>/dev/null || true)"
if [ -z "$mise_bin" ] && [ -x /etc/profiles/per-user/"${USER:-root}"/bin/mise ]; then
  mise_bin=/etc/profiles/per-user/"${USER:-root}"/bin/mise
fi
if [ -z "$mise_bin" ]; then
  echo "opensession-bun: mise not found on PATH" >&2
  exit 1
fi

export MISE_YES=1
exec "$mise_bin" exec -C "$cwd" -- bun "$@"
