#!/bin/bash

# Database Triggers Migration via Supabase REST API
# Execute SQL statements directly using curl

SUPABASE_URL="https://aeijlzokobuqcyznljvn.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM"

echo "🚀 Starting Database Triggers Migration..."
echo "🎯 Target: NEW Supabase project (aeijlzokobuqcyznljvn)"
echo ""

# Test database connection first
echo "🔍 Testing database connection..."
response=$(curl -s -w "HTTP_STATUS:%{http_code}" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Prefer: count=exact" \
    "$SUPABASE_URL/rest/v1/user_profiles?select=id&limit=1")

http_status=$(echo $response | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)

if [ "$http_status" = "200" ]; then
    echo "✅ Database connection successful"
else
    echo "❌ Database connection failed (HTTP $http_status)"
    echo "Response: $response"
    exit 1
fi

echo ""
echo "⚠️  IMPORTANT NOTE:"
echo "   SQL DDL operations (CREATE FUNCTION, CREATE TRIGGER) cannot be executed"
echo "   via Supabase's REST API with anon key due to security restrictions."
echo ""
echo "📋 Manual execution required via Supabase Dashboard:"
echo ""

echo "1️⃣  CREATE FUNCTIONS:"
echo "-------------------"
echo ""
echo "-- Function 1: handle_new_user"
echo "CREATE OR REPLACE FUNCTION public.handle_new_user()"
echo " RETURNS trigger"
echo " LANGUAGE plpgsql"
echo " SECURITY DEFINER"
echo "AS \$function\$"
echo "BEGIN"
echo "    INSERT INTO public.user_profiles (id, first_name, user_role)"
echo "    VALUES ("
echo "        NEW.id,"
echo "        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),"
echo "        COALESCE(NEW.raw_user_meta_data->>'user_role', 'student')"
echo "    );"
echo "    RETURN NEW;"
echo "END;"
echo "\$function\$;"
echo ""

echo "-- Function 2: update_updated_at_column"
echo "CREATE OR REPLACE FUNCTION public.update_updated_at_column()"
echo " RETURNS trigger"
echo " LANGUAGE plpgsql"
echo "AS \$function\$"
echo "BEGIN"
echo "    NEW.updated_at = NOW();"
echo "    RETURN NEW;"
echo "END;"
echo "\$function\$;"
echo ""

echo "2️⃣  CREATE TRIGGERS:"
echo "-------------------"
echo ""
echo "-- Trigger 1: on_auth_user_created"
echo "CREATE OR REPLACE TRIGGER on_auth_user_created"
echo "  AFTER INSERT"
echo "  ON auth.users"
echo "  FOR EACH ROW"
echo "  EXECUTE FUNCTION handle_new_user();"
echo ""

echo "-- Trigger 2: update_user_profiles_updated_at"
echo "CREATE OR REPLACE TRIGGER update_user_profiles_updated_at"
echo "  BEFORE UPDATE"
echo "  ON public.user_profiles"
echo "  FOR EACH ROW"
echo "  EXECUTE FUNCTION update_updated_at_column();"
echo ""

echo "3️⃣  EXECUTION INSTRUCTIONS:"
echo "--------------------------"
echo "1. Go to https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn"
echo "2. Navigate to: Database > SQL Editor"
echo "3. Create a new query and paste the SQL above"
echo "4. Execute each statement one by one"
echo "5. Verify in Database > Functions and Database > Triggers sections"
echo ""

echo "4️⃣  VERIFICATION AFTER EXECUTION:"
echo "--------------------------------"
echo "Expected results:"
echo "• 2 Functions created: handle_new_user, update_updated_at_column"
echo "• 2 Triggers created: on_auth_user_created, update_user_profiles_updated_at"
echo ""
echo "Test the triggers by:"
echo "• Creating a new user (should auto-create user_profiles record)"
echo "• Updating a user_profiles record (should update updated_at timestamp)"
echo ""

echo "🎯 MIGRATION SUMMARY:"
echo "===================="
echo "Functions to create: 2"
echo "Triggers to create: 2"
echo "Total SQL operations: 4"
echo ""
echo "⚠️  Manual execution required via Supabase Dashboard SQL Editor"
echo "✅ All SQL statements provided above for copy-paste execution"