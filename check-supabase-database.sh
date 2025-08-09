#!/bin/bash

# SnappyCards Database Structure Check
# This script connects to your Supabase project and examines the database structure
# Make sure you have supabase CLI installed: npm install -g supabase

echo "🔍 Checking SnappyCards Database Structure"
echo "=========================================="

# Your Supabase project details
SUPABASE_URL="https://aeijlzokobuqcyznljvn.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM"

# Function to run SQL query
run_sql() {
    local query="$1"
    local description="$2"
    
    echo ""
    echo "📋 $description"
    echo "----------------------------------------"
    
    # Use psql to connect directly to Supabase
    PGPASSWORD="$SUPABASE_PASSWORD" psql -h "db.aeijlzokobuqcyznljvn.supabase.co" -U "postgres" -d "postgres" -c "$query" 2>/dev/null || {
        echo "❌ Could not execute query. Make sure you have:"
        echo "   1. Set SUPABASE_PASSWORD environment variable"
        echo "   2. psql installed"
        echo "   3. Network access to Supabase"
        echo ""
        echo "Alternative: Run these queries manually in your Supabase SQL Editor:"
        echo "$query"
    }
}

echo "🚨 SETUP REQUIRED:"
echo "Before running this script, you need to:"
echo "1. Install psql: brew install postgresql (Mac) or apt-get install postgresql-client (Linux)"
echo "2. Set your Supabase database password:"
echo "   export SUPABASE_PASSWORD='your_db_password_here'"
echo ""
echo "Your database password can be found in:"
echo "- Supabase Dashboard → Settings → Database → Connection string"
echo ""

# Check if password is set
if [ -z "$SUPABASE_PASSWORD" ]; then
    echo "❌ SUPABASE_PASSWORD environment variable not set!"
    echo "Please run: export SUPABASE_PASSWORD='your_password_here'"
    exit 1
fi

# 1. List all tables in public schema
run_sql "SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;" "All Tables in Public Schema"

# 2. Check critical SnappyCards tables
echo ""
echo "🔍 CRITICAL SNAPPYCARDS TABLES CHECK"
echo "===================================="

critical_tables=(
    "user_profiles"
    "cards" 
    "flashcard_sets"
    "flashcard_set_cards"
    "user_card_progress"
    "user_set_progress" 
    "study_sessions"
    "schools"
    "categories"
    "classrooms"
)

for table in "${critical_tables[@]}"; do
    echo ""
    echo "📊 Table: $table"
    echo "------------------------"
    
    # Check if table exists and show structure
    run_sql "
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default,
            character_maximum_length
        FROM information_schema.columns 
        WHERE table_name = '$table' 
        AND table_schema = 'public'
        ORDER BY ordinal_position;
    " "Structure of $table"
    
    # Show record count
    run_sql "SELECT COUNT(*) as record_count FROM $table;" "Record count for $table"
done

# 3. Check sample data in key tables
echo ""
echo "📊 SAMPLE DATA CHECK"
echo "===================="

# Sample cards
run_sql "SELECT id, title, english_title, category, difficulty_level FROM cards LIMIT 5;" "Sample Cards (first 5)"

# Sample flashcard sets
run_sql "SELECT id, title, description, language_a, language_b, user_id FROM flashcard_sets LIMIT 5;" "Sample Flashcard Sets (first 5)"

# Sample set-card relationships
run_sql "SELECT fsc.id, fs.title as set_title, c.title as card_title FROM flashcard_set_cards fsc JOIN flashcard_sets fs ON fsc.set_id = fs.id JOIN cards c ON fsc.card_id = c.id LIMIT 5;" "Sample Set-Card Relationships (first 5)"

# User profiles
run_sql "SELECT id, email, user_role, school_id, created_at FROM user_profiles LIMIT 3;" "Sample User Profiles (first 3)"

# 4. Check RLS policies
echo ""
echo "🔐 ROW LEVEL SECURITY POLICIES"
echo "=============================="

run_sql "
    SELECT 
        t.table_name,
        p.policy_name,
        p.permissive,
        p.roles,
        p.cmd
    FROM information_schema.tables t
    LEFT JOIN pg_policies p ON p.tablename = t.table_name
    WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
    ORDER BY t.table_name, p.policy_name;
" "RLS Policies for all tables"

# 5. Check foreign key relationships
echo ""
echo "🔗 FOREIGN KEY RELATIONSHIPS"
echo "============================"

run_sql "
    SELECT
        tc.constraint_name,
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    ORDER BY tc.table_name, tc.constraint_name;
" "Foreign Key Relationships"

echo ""
echo "✅ Database structure check complete!"
echo ""
echo "📝 MANUAL CHECK ALTERNATIVE:"
echo "If the automated checks failed, you can manually run these queries in your Supabase SQL Editor:"
echo ""
echo "1. List all tables:"
echo "   SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
echo ""
echo "2. Check specific table structure:"
echo "   SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'your_table_name';"
echo ""
echo "3. Check record counts:"
echo "   SELECT 'table_name' as table, COUNT(*) as records FROM table_name;"