#\!/usr/bin/env bash
set -e
if [ \! -f backend/.env.local ]; then
  echo "❌ backend/.env.local nincs meg. Másold le a backend/.env.staging.local-t."
  exit 1
fi
set -a
# shellcheck disable=SC1091
source backend/.env.local
set +a
node backend/src/server.js