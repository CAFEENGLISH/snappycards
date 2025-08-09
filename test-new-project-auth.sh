#!/bin/bash

echo "🔧 Testing NEW Supabase Project Authentication"
echo "============================================="

SUPABASE_URL="https://aeijlzokobuqcyznljvn.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM"

echo "Testing the three users on NEW project..."
echo ""

# Array of users to test
declare -a users=(
    "zsolt.tasnadi@gmail.com:Teaching123:school_admin"
    "brad.pitt.budapest@gmail.com:Teaching123:teacher" 
    "vidamkos@gmail.com:Palacs1nta:student"
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

echo "🏁 NEW Project authentication test complete!"