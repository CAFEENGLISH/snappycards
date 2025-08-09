#!/bin/bash

echo "🔧 Creating users via Supabase Admin API"
echo "====================================="

SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzIwMzAzMSwiZXhwIjoyMDY4Nzc5MDMxfQ.0jZl6iSSz0BV9TlQhWOE5utuv71YetOWhsU0vQOdagM"
SUPABASE_URL="https://ycxqxdhaxehspypqbnpi.supabase.co"

echo "1️⃣ Creating zsolt.tasnadi@gmail.com..."
curl -X POST "${SUPABASE_URL}/auth/v1/admin/users" \
  -H "apikey: ${SERVICE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "zsolt.tasnadi@gmail.com",
    "password": "Teaching123",
    "email_confirm": true,
    "user_metadata": {
      "first_name": "Zsolt",
      "last_name": "Tasnadi",
      "user_role": "school_admin"
    }
  }'

echo -e "\n\n2️⃣ Creating brad.pitt.budapest@gmail.com..."
curl -X POST "${SUPABASE_URL}/auth/v1/admin/users" \
  -H "apikey: ${SERVICE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "brad.pitt.budapest@gmail.com", 
    "password": "Teaching123",
    "email_confirm": true,
    "user_metadata": {
      "first_name": "Brad",
      "last_name": "Pitt", 
      "user_role": "teacher"
    }
  }'

echo -e "\n\n✅ Done! Now test login with these users."