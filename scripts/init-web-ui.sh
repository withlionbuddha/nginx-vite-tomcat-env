#!/usr/bin/env sh
set -eu

web_ui_path=${WEB_UI_PATH:-/workspace/web-ui}

if ! command -v npm >/dev/null 2>&1; then
  echo "npm was not found. Run this script inside the Vite container." >&2
  exit 1
fi

if [ ! -d "$web_ui_path" ]; then
  echo "React workspace is missing: $web_ui_path. Check WEB_UI_HOST_PATH." >&2
  exit 1
fi

if [ ! -f "$web_ui_path/package.json" ]; then
  # A named volume creates node_modules before scaffolding. Do not let the
  # generator empty the bind mount or overwrite an existing source directory.
  existing_file=$(find "$web_ui_path" -mindepth 1 -maxdepth 1 \
    ! -name node_modules ! -name .git -print -quit)
  if [ -n "$existing_file" ]; then
    echo "package.json is missing in a non-empty workspace: $web_ui_path" >&2
    echo "Check WEB_UI_HOST_PATH; existing files have not been changed." >&2
    exit 1
  fi

  scaffold_root=$(mktemp -d)
  trap 'rm -rf "$scaffold_root"' EXIT
  (
    cd "$scaffold_root"
    npm_config_yes=true npm create vite@latest web-ui -- \
      --template react-ts --eslint --no-interactive --no-immediate
  )
  cp -R "$scaffold_root/web-ui/." "$web_ui_path/"
fi

(
  cd "$web_ui_path"
  if [ -f package-lock.json ]; then
    npm ci
  else
    npm install
  fi
)

echo "React workspace is ready: $web_ui_path"
