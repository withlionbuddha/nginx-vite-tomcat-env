#!/usr/bin/env sh
set -eu

compose_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
project_root=$(dirname "$compose_root")
web_ui_path="$project_root/web-ui"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm을 찾을 수 없습니다. Node.js LTS를 설치한 뒤 다시 실행하십시오." >&2
  exit 1
fi

if [ ! -f "$web_ui_path/package.json" ]; then
  (
    cd "$project_root"
    npm_config_yes=true npm create vite@latest web-ui -- --template react-ts --eslint --no-interactive
  )
fi

(
  cd "$web_ui_path"
  npm install
)

echo "web-ui 초기화가 완료되었습니다: $web_ui_path"
