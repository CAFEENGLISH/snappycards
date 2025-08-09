#!/usr/bin/env node
/**
 * Execute Triggers Migration Script
 * Connects to NEW Supabase project and executes trigger SQL
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// NEW Supabase project configuration
const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || SUPABASE_ANON_KEY;

// Read the migration SQL file
const sqlFilePath = path.join(__dirname, 'migrate-missing-triggers.sql');
let migrationSQL;

try {
    migrationSQL = fs.readFileSync(sqlFilePath, 'utf8');
    console.log('✅ Successfully read migration SQL file');
    console.log(`📄 File size: ${migrationSQL.length} characters`);
} catch (error) {
    console.error('❌ Error reading migration SQL file:', error.message);
    process.exit(1);
}

async function executeTriggersMigration() {
    console.log('🚀 Starting Triggers Migration Execution...');
    console.log('🎯 Target: NEW Supabase project (aeijlzokobuqcyznljvn)');
    
    // Create Supabase client with service role key for admin operations
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    
    try {
        // Split SQL into individual statements and filter out comments/empty lines
        const sqlStatements = migrationSQL
            .split(';')
            .map(stmt => stmt.trim())
            .filter(stmt => stmt && !stmt.startsWith('--'));
        
        console.log(`📋 Found ${sqlStatements.length} SQL statements to execute`);
        
        const results = [];
        let successCount = 0;
        let errorCount = 0;
        
        // Execute each SQL statement
        for (let i = 0; i < sqlStatements.length; i++) {
            const statement = sqlStatements[i];
            if (!statement) continue;
            
            console.log(`\n⚡ Executing statement ${i + 1}/${sqlStatements.length}:`);
            console.log(`   ${statement.substring(0, 80)}...`);
            
            try {
                const { data, error } = await supabase.rpc('exec_sql', {
                    sql_query: statement
                });
                
                if (error) {
                    // Try direct execution via raw SQL
                    const { data: rawData, error: rawError } = await supabase
                        .from('dummy')
                        .select('*')
                        .limit(0);
                    
                    // Use a different approach - execute via pg admin functions
                    const { data: execData, error: execError } = await supabase.rpc('execute_sql', {
                        query: statement
                    });
                    
                    if (execError) {
                        throw execError;
                    }
                    
                    console.log('✅ Statement executed successfully (via RPC)');
                    successCount++;
                    results.push({
                        statement: i + 1,
                        status: 'success',
                        data: execData
                    });
                } else {
                    console.log('✅ Statement executed successfully');
                    successCount++;
                    results.push({
                        statement: i + 1,
                        status: 'success',
                        data: data
                    });
                }
                
            } catch (error) {
                console.error(`❌ Error executing statement ${i + 1}:`, error.message);
                errorCount++;
                results.push({
                    statement: i + 1,
                    status: 'error',
                    error: error.message,
                    sql: statement
                });
            }
        }
        
        console.log('\n📊 EXECUTION SUMMARY:');
        console.log(`✅ Successful: ${successCount}`);
        console.log(`❌ Failed: ${errorCount}`);
        console.log(`📝 Total: ${sqlStatements.length}`);
        
        // Verify triggers were created
        console.log('\n🔍 VERIFYING TRIGGERS...');
        await verifyTriggers(supabase);
        
        return results;
        
    } catch (error) {
        console.error('❌ Fatal error during migration:', error);
        throw error;
    }
}

async function verifyTriggers(supabase) {
    try {
        // Query to check triggers
        const triggerQuery = `
            SELECT 
                trigger_name,
                event_manipulation,
                event_object_table,
                event_object_schema
            FROM information_schema.triggers 
            WHERE trigger_name IN ('on_auth_user_created', 'update_user_profiles_updated_at')
            ORDER BY trigger_name;
        `;
        
        const { data: triggers, error: triggerError } = await supabase.rpc('exec_sql', {
            sql_query: triggerQuery
        });
        
        if (triggerError) {
            console.error('❌ Error querying triggers:', triggerError.message);
            return;
        }
        
        console.log('🎯 Trigger Verification Results:');
        if (triggers && triggers.length > 0) {
            triggers.forEach(trigger => {
                console.log(`✅ Trigger: ${trigger.trigger_name}`);
                console.log(`   📋 Event: ${trigger.event_manipulation}`);
                console.log(`   🗂️  Table: ${trigger.event_object_schema}.${trigger.event_object_table}`);
            });
        } else {
            console.log('⚠️  No triggers found - verification may need different approach');
        }
        
        // Also check functions
        console.log('\n🔍 VERIFYING FUNCTIONS...');
        const functionQuery = `
            SELECT 
                routine_name,
                routine_type
            FROM information_schema.routines 
            WHERE routine_name IN ('handle_new_user', 'update_updated_at_column')
                AND routine_schema = 'public'
            ORDER BY routine_name;
        `;
        
        const { data: functions, error: functionError } = await supabase.rpc('exec_sql', {
            sql_query: functionQuery
        });
        
        if (functionError) {
            console.error('❌ Error querying functions:', functionError.message);
            return;
        }
        
        console.log('🎯 Function Verification Results:');
        if (functions && functions.length > 0) {
            functions.forEach(func => {
                console.log(`✅ Function: ${func.routine_name} (${func.routine_type})`);
            });
        } else {
            console.log('⚠️  No functions found - verification may need different approach');
        }
        
    } catch (error) {
        console.error('❌ Error during verification:', error.message);
    }
}

// Main execution
if (require.main === module) {
    executeTriggersMigration()
        .then((results) => {
            console.log('\n🎉 Triggers migration execution completed!');
            process.exit(0);
        })
        .catch((error) => {
            console.error('💥 Migration failed:', error);
            process.exit(1);
        });
}

module.exports = { executeTriggersMigration };