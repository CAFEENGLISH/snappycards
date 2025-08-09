#!/usr/bin/env zsh
set -e
if [ ! -f ./.env.production ]; then
  echo "❌ Missing .env.production"; exit 1
fi
set -a
source ./.env.production
set +a
supabase link --project-ref "$SUPABASE_PROJECT_REF"
echo "✅ Linked to PRODUCTION ($SUPABASE_PROJECT_REF)"
grep -n 'project_ref' supabase/config.toml || true
