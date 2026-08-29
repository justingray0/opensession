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
  local checkout="${OPENSESSION_DEPLOY_CHECKOUT:-}"

  if [ -z "$candidate" ]; then
    candidate="$(command -v bun 2>/dev/null || true)"
  fi

  case "$candidate" in
    */opensession-bun|opensession-bun)
      candidate=""
      ;;
  esac

  # Release worktrees are fresh git checkouts; mise shims and opensession-bun
  # resolve packageManager from that tree's untrusted mise.toml. Resolve the
  # real bun binary from the trusted deploy checkout instead.
  case "$candidate" in
    ""|*/mise/shims/*)
      if [ -n "$checkout" ] && [ -f "$checkout/mise.toml" ]; then
        local mise_bin
        mise_bin="$(command -v mise 2>/dev/null || true)"
        if [ -z "$mise_bin" ] && [ -x "/etc/profiles/per-user/${USER:-root}/bin/mise" ]; then
          mise_bin="/etc/profiles/per-user/${USER:-root}/bin/mise"
        fi
        if [ -n "$mise_bin" ]; then
          candidate="$("$mise_bin" exec -C "$checkout" -- mise which bun 2>/dev/null || true)"
        fi
      fi
      ;;
  esac

  if [ -z "$candidate" ]; then
    candidate="$(command -v bun 2>/dev/null || true)"
  fi

  printf '%s\n' "$candidate"
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
