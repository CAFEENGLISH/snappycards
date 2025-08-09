#!/bin/bash

# Test Authentication Fix Verification
echo "🔧 Testing SnappyCards Authentication Fix"
echo "========================================="

SUPABASE_URL="https://ycxqxdhaxehspypqbnpi.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g"

echo "Testing the three fixed users..."
echo ""

# Array of users to test
declare -a users=(
    "zsolt.tasnadi@gmail.com:Teaching123:school_admin"
    "brad.pitt.budapest@gmail.com:Teaching123:teacher" 
    "testuser@example.com:Teaching123:student"
)

# Test each user
for user_info in "${users[@]}"; do
    IFS=':' read -r email password expected_role <<< "$user_info"
    
    echo "🧪 Testing: $email (expected role: $expected_role)"
    echo "----------------------------------------"
    
    # Attempt authentication
    AUTH_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
        -H "apikey: ${ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$email\",
            \"password\": \"$password\"
        }")
    
    # Check if authentication was successful
    ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.access_token // empty')
    USER_ID=$(echo "$AUTH_RESPONSE" | jq -r '.user.id // empty')
    
    if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
        echo "✅ Authentication successful!"
        echo "   User ID: $USER_ID"
        
        # Test user_profiles access
        echo "   Testing user_profiles access..."
        PROFILE_RESPONSE=$(curl -s -H "apikey: ${ANON_KEY}" \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            "${SUPABASE_URL}/rest/v1/user_profiles?select=id,email,first_name,user_role&id=eq.$USER_ID")
        
        ACTUAL_ROLE=$(echo "$PROFILE_RESPONSE" | jq -r '.[0].user_role // empty')
        FIRST_NAME=$(echo "$PROFILE_RESPONSE" | jq -r '.[0].first_name // empty')
        
        if [ -n "$ACTUAL_ROLE" ] && [ "$ACTUAL_ROLE" != "null" ]; then
            echo "✅ Profile access successful!"
            echo "   Name: $FIRST_NAME"
            echo "   Role: $ACTUAL_ROLE"
            
            if [ "$ACTUAL_ROLE" = "$expected_role" ]; then
                echo "✅ Role matches expected: $expected_role"
            else
                echo "⚠️  Role mismatch - Expected: $expected_role, Got: $ACTUAL_ROLE"
            fi
        else
            echo "❌ Profile access failed"
            echo "   Response: $PROFILE_RESPONSE"
        fi
        
    else
        echo "❌ Authentication failed"
        ERROR_MESSAGE=$(echo "$AUTH_RESPONSE" | jq -r '.error_description // .message // "Unknown error"')
        echo "   Error: $ERROR_MESSAGE"
    fi
    
    echo ""
done

echo "🏁 Authentication fix verification complete!"
echo ""
echo "📋 Summary:"
echo "If all users show ✅ Authentication successful and ✅ Profile access successful,"
echo "then the auth.users fix has been applied correctly."
echo ""
echo "Next steps:"
echo "1. Run the fix-auth-users.sql script in Supabase SQL Editor"
echo "2. Run this test script again to verify the fix"
echo "3. Test the application login functionality"