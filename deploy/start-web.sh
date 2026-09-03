#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd -- "$script_dir/.." && pwd)"
skip_build=false
open_browser=false
port=3080

usage() {
  cat <<'HELP'
Usage: ./deploy/start-web.sh [options]

Options:
  --skip-build, -SkipBuild       Reuse existing build artifacts.
  --open-browser, -OpenBrowser   Open the tokenized URL automatically.
  --port PORT, -Port PORT        Use a different port (1-65535).
  --help, -h                     Show this help.
HELP
}

fail() {
  printf '[start-web] %s\n' "$1" >&2
  exit 1
}

stop_port_listeners() {
  local listener_pids
  command -v lsof >/dev/null 2>&1 || fail "lsof was not found. Install lsof or free port $port manually."
  listener_pids="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null || true)"
  if [[ -z "$listener_pids" ]]; then
    return
  fi
  while IFS= read -r process_id; do
    [[ "$process_id" =~ ^[0-9]+$ ]] || continue
    [[ "$process_id" == "$$" ]] && continue
    printf 'Stopping process PID=%s listening on port %s.\n' "$process_id" "$port"
    kill "$process_id" 2>/dev/null || {
      kill -0 "$process_id" 2>/dev/null && fail "Could not stop process PID=$process_id on port $port."
    }
  done <<< "$listener_pids"
}

while (($# > 0)); do
  case "$1" in
    --skip-build|-SkipBuild|-NoBuild)
      skip_build=true
      shift
      ;;
    --open-browser|-OpenBrowser)
      open_browser=true
      shift
      ;;
    --port|-Port)
      (($# >= 2)) || fail "--port requires a value."
      port="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

[[ "$port" =~ ^[0-9]+$ ]] || fail "Port must be an integer from 1 to 65535."
((port >= 1 && port <= 65535)) || fail "Port must be an integer from 1 to 65535."
command -v pnpm >/dev/null 2>&1 || fail "pnpm was not found. Enable Corepack or install pnpm first."
[[ -f "$repository_root/package.json" ]] || fail "Repository package.json was not found: $repository_root"

cd "$repository_root"
printf 'Repository: %s\nWeb port: 127.0.0.1:%s\n' "$repository_root" "$port"

if [[ "$skip_build" == true ]]; then
  required_artifacts=(
    apps/cli/lib/bin.js
    apps/web/dist/index.html
    packages/client/ui-agent-preset/lib/client.js
  )
  missing_artifacts=()
  for artifact in "${required_artifacts[@]}"; do
    [[ -f "$repository_root/$artifact" ]] || missing_artifacts+=("$artifact")
  done
  ((${#missing_artifacts[@]} == 0)) || fail "Build skipped, but artifacts are missing: ${missing_artifacts[*]}. Remove --skip-build and retry."
  printf 'Using existing build artifacts.\n'
else
  printf 'Building Host, Client, and Web artifacts. Please wait.\n'
  pnpm run build
  printf 'Build complete.\n'
fi

stop_port_listeners
printf 'Starting Web service. Press Ctrl+C to stop it.\n'
printf 'Open the complete tokenized URL printed below in your browser.\n'

set +e
pnpm dsh web --no-open --port "$port" 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [[ "$line" =~ ^dsh\ web:\ (https?://[^[:space:]]+)$ ]]; then
    frontend_url="${BASH_REMATCH[1]}"
    printf '\nFrontend is ready. Open this URL in your browser:\n%s\n' "$frontend_url"
    if [[ "$open_browser" == true ]]; then
      if command -v open >/dev/null 2>&1; then
        open "$frontend_url"
      elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$frontend_url" >/dev/null 2>&1 &
      else
        printf '[start-web] No browser opener found; open the URL manually.\n' >&2
      fi
    fi
  fi
done
service_status=${PIPESTATUS[0]}
set -e
((service_status == 0)) || fail "Web service exited with code $service_status."
