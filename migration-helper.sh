#!/bin/bash

# Supabase Migration Helper Script
# Target: aeijlzokobuqcyznljvn.supabase.co

echo "🚀 Supabase Migration Helper"
echo "Target Project: aeijlzokobuqcyznljvn"
echo "=================================="

PROJECT_REF="aeijlzokobuqcyznljvn"
DB_PASSWORD="${SUPABASE_DB_PASSWORD}"

if [ -z "$DB_PASSWORD" ]; then
    echo "⚠️  Please set SUPABASE_DB_PASSWORD environment variable"
    echo "   export SUPABASE_DB_PASSWORD='your-db-password'"
    exit 1
fi

echo "Step 1: Migrating Functions..."
if [ -f "migrate-missing-functions.sql" ]; then
    echo "📄 Found migrate-missing-functions.sql"
    echo "   -> Manual execution required in Supabase Dashboard"
    echo "   -> URL: https://supabase.com/dashboard/project/${PROJECT_REF}/sql"
else
    echo "❌ migrate-missing-functions.sql not found!"
    exit 1
fi

echo ""
echo "Step 2: Migrating Triggers..."
if [ -f "migrate-missing-triggers.sql" ]; then
    echo "📄 Found migrate-missing-triggers.sql"
    echo "   -> Execute after Step 1 completes"
else
    echo "❌ migrate-missing-triggers.sql not found!"
fi

echo ""
echo "Step 3: Migrating RLS Policies..."
if [ -f "migrate-all-rls-policies.sql" ]; then
    echo "📄 Found migrate-all-rls-policies.sql"
    echo "   -> Execute after Step 2 completes"
    echo "   -> CRITICAL: 44 security policies"
else
    echo "❌ migrate-all-rls-policies.sql not found!"
fi

echo ""
echo "Step 4: Migrating Storage..."
if [ -f "migrate-storage-data.sql" ]; then
    echo "📄 Found migrate-storage-data.sql"
    echo "   -> Execute after Step 3 completes"
    echo "   -> Note: Only metadata, files need separate copying"
else
    echo "❌ migrate-storage-data.sql not found!"
fi

echo ""
echo "📋 EXECUTION CHECKLIST:"
echo "☐ 1. Execute migrate-missing-functions.sql"
echo "☐ 2. Execute migrate-missing-triggers.sql" 
echo "☐ 3. Execute migrate-all-rls-policies.sql"
echo "☐ 4. Execute migrate-storage-data.sql"
echo "☐ 5. Verify each step with provided queries"

echo ""
echo "🔗 Quick Links:"
echo "   Dashboard: https://supabase.com/dashboard/project/${PROJECT_REF}"
echo "   SQL Editor: https://supabase.com/dashboard/project/${PROJECT_REF}/sql"
echo "   Storage: https://supabase.com/dashboard/project/${PROJECT_REF}/storage/buckets"

echo ""
echo "⚡ CRITICAL: Execute in exact order - dependencies exist between steps!"