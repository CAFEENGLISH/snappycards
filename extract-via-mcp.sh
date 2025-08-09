#!/bin/bash

# =====================================================
# EXTRACT MISSING TABLES VIA SUPABASE MCP SERVER
# =====================================================
# This script uses the installed Supabase MCP server to extract 
# table structures from the old project
# =====================================================

echo "🚀 Extracting missing table structures via MCP server..."
echo "Target tables: classroom_details, classroom_members, favicons"
echo ""

# Check if MCP server is available
if ! command -v mcp-server-supabase &> /dev/null; then
    echo "❌ mcp-server-supabase not found in PATH"
    echo "Available MCP binaries:"
    find /opt/homebrew/bin -name "*mcp*" 2>/dev/null
    exit 1
fi

echo "✅ Found mcp-server-supabase"

# You need to set these environment variables with your old project credentials
export SUPABASE_URL="https://ycxqxdhaxehspypqbnpi.supabase.co"
export SUPABASE_KEY="YOUR_OLD_PROJECT_SERVICE_ROLE_KEY"  # Replace with actual key

if [ "$SUPABASE_KEY" = "YOUR_OLD_PROJECT_SERVICE_ROLE_KEY" ]; then
    echo "❌ Please set the SUPABASE_KEY environment variable with your old project's service role key"
    echo "You can find this in your old Supabase project settings"
    exit 1
fi

echo "🔍 Connecting to old project: $SUPABASE_URL"

# Create temporary directory for output
mkdir -p ./extracted_tables
OUTPUT_DIR="./extracted_tables"

echo ""
echo "📊 Extracting column structures..."

# Extract column structures
cat << 'EOF' > "$OUTPUT_DIR/extract_columns.sql"
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name IN ('classroom_details', 'classroom_members', 'favicons')
ORDER BY table_name, ordinal_position;
EOF

# Extract favicons data
cat << 'EOF' > "$OUTPUT_DIR/extract_favicons_data.sql"
SELECT * FROM favicons;
EOF

# Extract constraints
cat << 'EOF' > "$OUTPUT_DIR/extract_constraints.sql"
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM information_schema.table_constraints AS tc
LEFT JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('classroom_details', 'classroom_members', 'favicons')
ORDER BY tc.table_name, tc.constraint_type;
EOF

echo "📝 SQL query files created in $OUTPUT_DIR/"
echo ""
echo "🔧 To use these files:"
echo "1. Set your old project credentials:"
echo "   export SUPABASE_URL='https://ycxqxdhaxehspypqbnpi.supabase.co'"
echo "   export SUPABASE_KEY='your_old_project_service_role_key'"
echo ""
echo "2. Run the MCP server with each query file:"
echo "   mcp-server-supabase --query \"\$(cat $OUTPUT_DIR/extract_columns.sql)\""
echo "   mcp-server-supabase --query \"\$(cat $OUTPUT_DIR/extract_favicons_data.sql)\""
echo "   mcp-server-supabase --query \"\$(cat $OUTPUT_DIR/extract_constraints.sql)\""
echo ""
echo "3. Or use the direct SQL file in Supabase SQL Editor:"
echo "   ./extract-missing-tables.sql"
echo ""

# Try to run the extractions if credentials are set properly
if [ "$SUPABASE_KEY" != "YOUR_OLD_PROJECT_SERVICE_ROLE_KEY" ] && [ ! -z "$SUPABASE_KEY" ]; then
    echo "🔄 Attempting to run extractions..."
    
    echo ""
    echo "1️⃣ Column structures:"
    echo "========================="
    mcp-server-supabase --query "$(cat "$OUTPUT_DIR/extract_columns.sql")" 2>/dev/null || echo "❌ Failed to extract columns"
    
    echo ""
    echo "2️⃣ Favicons data:"
    echo "================="
    mcp-server-supabase --query "$(cat "$OUTPUT_DIR/extract_favicons_data.sql")" 2>/dev/null || echo "❌ Failed to extract favicons data"
    
    echo ""
    echo "3️⃣ Constraints:"
    echo "==============="
    mcp-server-supabase --query "$(cat "$OUTPUT_DIR/extract_constraints.sql")" 2>/dev/null || echo "❌ Failed to extract constraints"
    
else
    echo "⏭️ Skipping automatic extraction - credentials not set"
fi

echo ""
echo "✅ Extraction script completed!"
echo "📁 Query files saved in: $OUTPUT_DIR/"
echo ""
echo "🎯 Next steps:"
echo "1. Get your old project's service role key"
echo "2. Set the SUPABASE_KEY environment variable"
echo "3. Re-run this script, or use the SQL file directly in Supabase"