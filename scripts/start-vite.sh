#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$script_dir/init-web-ui.sh"
cd "${WEB_UI_PATH:-/workspace/web-ui}"
exec npm run dev -- --host 0.0.0.0 --port 8183 --strictPort
