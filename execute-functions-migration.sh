#!/bin/bash

# =====================================================
# EXECUTE FUNCTIONS MIGRATION FOR NEW SUPABASE PROJECT
# =====================================================
# This script executes the database functions migration
# for the NEW SnappyCards Supabase project (aeijlzokobuqcyznljvn)
# =====================================================

echo "🚀 Executing Database Functions Migration for SnappyCards..."
echo "Target: NEW Supabase project (aeijlzokobuqcyznljvn - snappycards2025)"
echo ""

# Check if MCP server is available
if ! command -v mcp-server-supabase &> /dev/null; then
    echo "❌ mcp-server-supabase not found in PATH"
    echo "Available MCP binaries:"
    find /opt/homebrew/bin -name "*mcp*" 2>/dev/null
    exit 1
fi

echo "✅ Found mcp-server-supabase"

# Set environment variables for NEW project
export SUPABASE_URL="https://aeijlzokobuqcyznljvn.supabase.co"
export SUPABASE_KEY="YOUR_NEW_PROJECT_SERVICE_ROLE_KEY"  # Replace with actual service role key

if [ "$SUPABASE_KEY" = "YOUR_NEW_PROJECT_SERVICE_ROLE_KEY" ]; then
    echo "❌ Please set the SUPABASE_KEY environment variable with your NEW project's service role key"
    echo "You can find this in your NEW Supabase project settings:"
    echo "   1. Go to https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn"
    echo "   2. Go to Settings → API"
    echo "   3. Copy the 'service_role' key (not the anon key)"
    echo ""
    echo "Then run: export SUPABASE_KEY='your_service_role_key_here'"
    echo "And re-run this script."
    exit 1
fi

echo "🔍 Connecting to NEW project: $SUPABASE_URL"
echo ""

# Function to execute SQL and check results
execute_function() {
    local function_name="$1"
    local sql_command="$2"
    
    echo "📝 Creating function: $function_name"
    echo "========================="
    
    # Execute the SQL command
    result=$(echo "$sql_command" | mcp-server-supabase --query "$(cat)" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully created function: $function_name"
        echo "$result" | head -3
    else
        echo "❌ Failed to create function: $function_name"
        echo "Error: $result"
        return 1
    fi
    echo ""
}

# Read the migration file
MIGRATION_FILE="./migrate-missing-functions.sql"

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "📖 Reading migration file: $MIGRATION_FILE"
echo ""

# Execute each function individually
echo "🔄 Executing function migrations..."
echo ""

# Function 1: create_classroom
CREATE_CLASSROOM_SQL=$(awk '/-- Function: create_classroom/,/^$/' "$MIGRATION_FILE")
execute_function "create_classroom" "$CREATE_CLASSROOM_SQL"

# Function 2: generate_invite_code  
GENERATE_CODE_SQL=$(awk '/-- Function: generate_invite_code/,/^$/' "$MIGRATION_FILE")
execute_function "generate_invite_code" "$GENERATE_CODE_SQL"

# Function 3: handle_new_user
HANDLE_USER_SQL=$(awk '/-- Function: handle_new_user/,/^$/' "$MIGRATION_FILE")
execute_function "handle_new_user" "$HANDLE_USER_SQL"

# Function 4: join_classroom_with_code
JOIN_CLASSROOM_SQL=$(awk '/-- Function: join_classroom_with_code/,/^$/' "$MIGRATION_FILE")
execute_function "join_classroom_with_code" "$JOIN_CLASSROOM_SQL"

echo "🔍 Verifying functions were created..."
echo "====================================="

# Verify functions exist
VERIFY_SQL="SELECT 
    routine_name as function_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('create_classroom', 'generate_invite_code', 'handle_new_user', 'join_classroom_with_code')
ORDER BY routine_name;"

echo "📊 Querying existing functions..."
verification_result=$(echo "$VERIFY_SQL" | mcp-server-supabase --query "$(cat)" 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Functions verification successful:"
    echo "$verification_result"
    
    # Count functions
    function_count=$(echo "$verification_result" | grep -c "create_classroom\|generate_invite_code\|handle_new_user\|join_classroom_with_code")
    echo ""
    echo "📈 RESULTS SUMMARY:"
    echo "=================="
    echo "• Functions found: $function_count / 4"
    
    if [ "$function_count" -eq 4 ]; then
        echo "🎉 SUCCESS! All 4 functions were created successfully:"
        echo "   ✓ handle_new_user() - trigger function for new user creation"
        echo "   ✓ create_classroom() - creates classroom with invite code"
        echo "   ✓ generate_invite_code() - generates unique classroom invite codes"
        echo "   ✓ join_classroom_with_code() - allows students to join classrooms"
    else
        echo "⚠️  WARNING: Only $function_count out of 4 functions were created"
        echo "Please check the errors above and retry failed functions"
    fi
else
    echo "❌ Functions verification failed:"
    echo "$verification_result"
fi

echo ""
echo "✅ Database Functions Migration completed!"
echo ""
echo "🎯 Next steps:"
echo "1. Verify the functions work by testing them in your application"
echo "2. Check that the trigger for handle_new_user() is also created"
echo "3. Test classroom creation and joining functionality"