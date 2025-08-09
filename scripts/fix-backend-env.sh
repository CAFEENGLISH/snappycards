#\!/usr/bin/env bash
set -euo pipefail

file="backend/.env.local"
st_ref="sdundzbolxaqfljmoune"
st_url="https://${st_ref}.supabase.co"

if [ \! -f "$file" ]; then
  echo "❌ $file nem található. Kérlek hozz létre egyet (pl. backend/.env.staging.local alapján)."
  exit 1
fi

# 1) STAGING URL beállítása
if grep -q '^SUPABASE_URL=' "$file"; then
  sed -i.bak "s|^SUPABASE_URL=.*|SUPABASE_URL=${st_url}|" "$file"
else
  printf "\nSUPABASE_URL=%s\n" "$st_url" >> "$file"
fi

# 2) ROLE_KEY → SERVICE_KEY migráció (ha van ROLE_KEY érték és a SERVICE_KEY üres/hiányzik)
role_val="$(grep -E '^SUPABASE_SERVICE_ROLE_KEY=' "$file" | sed 's/^[^=]*=//;s/[[:space:]]*$//')"
serv_val="$(grep -E '^SUPABASE_SERVICE_KEY=' "$file" | sed 's/^[^=]*=//;s/[[:space:]]*$//')"

if [ -n "${role_val:-}" ] && [ -z "${serv_val:-}" ]; then
  if grep -q '^SUPABASE_SERVICE_KEY=' "$file"; then
    sed -i.bak "s|^SUPABASE_SERVICE_KEY=.*|SUPABASE_SERVICE_KEY=${role_val}|" "$file"
  else
    printf "SUPABASE_SERVICE_KEY=%s\n" "$role_val" >> "$file"
  fi
  serv_val="$role_val"
fi

# 3) Ha továbbra sincs SERVICE_KEY, kérd be
if [ -z "${serv_val:-}" ]; then
  stty -echo; printf "Paste STAGING SUPABASE_SERVICE_KEY (service role): "; read key; stty echo; echo
  if [ -z "${key:-}" ]; then echo "❌ Üres kulcs, kilépek."; exit 1; fi
  if grep -q '^SUPABASE_SERVICE_KEY=' "$file"; then
    sed -i.bak "s|^SUPABASE_SERVICE_KEY=.*|SUPABASE_SERVICE_KEY=${key}|" "$file"
  else
    printf "SUPABASE_SERVICE_KEY=%s\n" "$key" >> "$file"
  fi
fi

echo "---- STATUS ($file) ----"
for k in SUPABASE_URL SUPABASE_SERVICE_KEY SUPABASE_SERVICE_ROLE_KEY; do
  if grep -q "^$k=" "$file"; then
    v="$(grep "^$k=" "$file" | sed 's/^[^=]*=//')"
    [ -n "$v" ] && echo "$k = SET" || echo "$k = EMPTY"
  else
    echo "$k = MISSING"
  fi
done