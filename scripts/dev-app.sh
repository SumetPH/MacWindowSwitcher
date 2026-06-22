#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$project_root/scripts/build-app.sh" debug
open "$project_root/.build/app/Mac Window Switcher.app"
