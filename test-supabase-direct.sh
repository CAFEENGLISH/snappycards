#!/bin/bash

# Test Supabase Authentication Directly
echo "🔍 Testing Supabase Authentication Direct API Calls"
echo "=================================================="

SUPABASE_URL="https://ycxqxdhaxehspypqbnpi.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g"

echo "1️⃣ Testing Auth Health..."
curl -s "${SUPABASE_URL}/auth/v1/health" | jq '.' || echo "Auth health check failed"

echo -e "\n2️⃣ Testing user_profiles table access..."
curl -s -H "apikey: ${ANON_KEY}" \
     -H "Authorization: Bearer ${ANON_KEY}" \
     "${SUPABASE_URL}/rest/v1/user_profiles?select=id,email,user_role&limit=5" | jq '.' || echo "user_profiles access failed"

echo -e "\n3️⃣ Testing authentication attempt..."
AUTH_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "vidamkos@gmail.com",
    "password": "Palacs1nta"
  }')

echo "$AUTH_RESPONSE" | jq '.' || echo "Authentication failed"

# Check if we got an access token
ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.access_token // empty')

if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
    echo -e "\n4️⃣ ✅ Authentication successful! Testing authenticated user_profiles access..."
    curl -s -H "apikey: ${ANON_KEY}" \
         -H "Authorization: Bearer ${ACCESS_TOKEN}" \
         "${SUPABASE_URL}/rest/v1/user_profiles?select=*&email=eq.vidamkos@gmail.com" | jq '.'
else
    echo -e "\n4️⃣ ❌ Authentication failed - no access token received"
fi

echo -e "\n🏁 Test completed"