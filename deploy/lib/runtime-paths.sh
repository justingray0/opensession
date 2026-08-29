# Shared path resolution for deploy scripts on minimal/NixOS hosts.
#
# /bin/bash is not guaranteed to exist even when bash is on PATH. The
# opensession-bun wrapper runs Bun against the live release tree and must not
# be used while preparing detached release worktrees.

resolve_bash() {
  if [ -n "${BASH:-}" ] && [ -x "$BASH" ]; then
    printf '%s\n' "$BASH"
    return 0
  fi
  command -v bash 2>/dev/null || true
}

resolve_deploy_bun() {
  local candidate="${1:-}"
  if [ -z "$candidate" ]; then
    candidate="$(command -v bun 2>/dev/null || true)"
  fi
  case "$candidate" in
    */opensession-bun|opensession-bun)
      command -v bun 2>/dev/null || true
      ;;
    *)
      printf '%s\n' "$candidate"
      ;;
  esac
}

run_bun_in() {
  local dir="$1"
  shift
  case "$BUN_BIN" in
    */opensession-bun|opensession-bun)
      (cd "$dir" && OPENSESSION_BUN_CWD="$dir" "$BUN_BIN" "$@")
      ;;
    *)
      (cd "$dir" && "$BUN_BIN" "$@")
      ;;
  esac
}
