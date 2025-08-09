#\!/usr/bin/env bash
set -euo pipefail

BASE="${BASE:-http://localhost:8000}"
ORIG="${ORIG:-http://localhost:3000}"
EMAIL="test.$(date +%s)@example.com"

echo "== Smoke: /health =="
curl -s -i -H "Origin: $ORIG" "$BASE/health" | sed -n '1,20p'

echo
echo "== Smoke: /register =="
# A te endpointod jelenleg ezeket várja: email, firstName, language, userRole
curl -s -i -H "Origin: $ORIG" -H "Content-Type: application/json" \
  -X POST "$BASE/register" \
  -d '{
    "email": "'"$EMAIL"'",
    "firstName": "Test",
    "language": "hu",
    "userRole": "student"
  }' | sed -n '1,160p'

echo
echo "== Supabase URL a logból (ha kiírja) =="
{ grep -F "🔗 Using Supabase project:" backend/server.log 2>/dev/null || true; } | tail -1 || true

echo
echo "Kész. BASE=$BASE  ORIG=$ORIG  EMAIL=$EMAIL"
