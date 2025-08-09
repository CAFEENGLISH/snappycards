#!/usr/bin/env zsh
set -e
if [ ! -f ./.env.staging ]; then
  echo "❌ Missing .env.staging"; exit 1
fi
set -a
source ./.env.staging
set +a
supabase link --project-ref "$SUPABASE_PROJECT_REF"
echo "✅ Linked to STAGING ($SUPABASE_PROJECT_REF)"
grep -n 'project_ref' supabase/config.toml || true
