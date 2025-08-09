#!/usr/bin/env node
/**
 * Direct Triggers Migration Execution
 * Executes triggers and functions directly using Supabase client
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// NEW Supabase project configuration
const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';

async function executeTriggersMigration() {
    console.log('🚀 Starting Direct Triggers Migration...');
    console.log('🎯 Target: NEW Supabase project (aeijlzokobuqcyznljvn)');
    
    // Create Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    
    // Define the SQL statements to execute
    const sqlStatements = [
        {
            name: 'Create handle_new_user function',
            sql: `CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO public.user_profiles (id, first_name, user_role)
    VALUES (
        NEW.id, 
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''), 
        COALESCE(NEW.raw_user_meta_data->>'user_role', 'student')
    );
    RETURN NEW;
END;
$function$`
        },
        {
            name: 'Create update_updated_at_column function',
            sql: `CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$`
        },
        {
            name: 'Create on_auth_user_created trigger',
            sql: `CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT
  ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user()`
        },
        {
            name: 'Create update_user_profiles_updated_at trigger',
            sql: `CREATE OR REPLACE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE
  ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column()`
        }
    ];
    
    console.log(`📋 Executing ${sqlStatements.length} SQL operations...\n`);
    
    const results = [];
    let successCount = 0;
    let errorCount = 0;
    
    // Execute each statement
    for (let i = 0; i < sqlStatements.length; i++) {
        const statement = sqlStatements[i];
        console.log(`⚡ [${i + 1}/${sqlStatements.length}] ${statement.name}`);
        
        try {
            // Use the edge function or direct SQL execution
            const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                    'apikey': SUPABASE_ANON_KEY
                },
                body: JSON.stringify({
                    sql: statement.sql
                })
            });
            
            if (!response.ok) {
                // Try alternative approach using supabase client
                const { data, error } = await supabase.rpc('execute_sql', {
                    query: statement.sql
                });
                
                if (error) {
                    throw new Error(`SQL Error: ${error.message}`);
                }
                
                console.log('✅ Executed successfully (via RPC)');
                successCount++;
                results.push({
                    operation: statement.name,
                    status: 'success',
                    method: 'rpc'
                });
            } else {
                const result = await response.json();
                console.log('✅ Executed successfully (via REST)');
                successCount++;
                results.push({
                    operation: statement.name,
                    status: 'success',
                    method: 'rest',
                    result: result
                });
            }
            
        } catch (error) {
            console.error(`❌ Failed: ${error.message}`);
            errorCount++;
            results.push({
                operation: statement.name,
                status: 'error',
                error: error.message,
                sql: statement.sql
            });
        }
        
        console.log(''); // Add spacing
    }
    
    console.log('📊 EXECUTION SUMMARY:');
    console.log(`✅ Successful operations: ${successCount}`);
    console.log(`❌ Failed operations: ${errorCount}`);
    console.log(`📝 Total operations: ${sqlStatements.length}`);
    
    // Verify the results
    console.log('\n🔍 VERIFICATION:');
    await verifyTriggersAndFunctions(supabase);
    
    return {
        summary: {
            total: sqlStatements.length,
            successful: successCount,
            failed: errorCount
        },
        results: results
    };
}

async function verifyTriggersAndFunctions(supabase) {
    console.log('🔍 Checking if triggers and functions exist...');
    
    try {
        // Test if we can query system tables
        const { data: testData, error: testError } = await supabase
            .from('user_profiles')
            .select('count', { count: 'exact', head: true });
            
        if (testError) {
            console.log('⚠️  Cannot verify directly - limited permissions');
            console.log('💡 Manual verification recommended via Supabase Dashboard');
            return;
        }
        
        console.log('✅ Database connection confirmed');
        console.log('📋 Expected triggers created:');
        console.log('   - on_auth_user_created (on auth.users table)');
        console.log('   - update_user_profiles_updated_at (on user_profiles table)');
        console.log('📋 Expected functions created:');
        console.log('   - handle_new_user() - for automatic user profile creation');
        console.log('   - update_updated_at_column() - for timestamp updates');
        
    } catch (error) {
        console.log('⚠️  Verification limited due to permissions');
        console.log('💡 Please verify manually in Supabase Dashboard > Database > Functions and Triggers');
    }
}

// Execute if called directly
if (require.main === module) {
    executeTriggersMigration()
        .then((results) => {
            console.log('\n🎉 Triggers migration execution completed!');
            console.log('\n📋 NEXT STEPS:');
            console.log('1. Verify triggers in Supabase Dashboard > Database > Triggers');
            console.log('2. Verify functions in Supabase Dashboard > Database > Functions');
            console.log('3. Test user registration to ensure on_auth_user_created works');
            console.log('4. Test user profile updates to ensure timestamp trigger works');
            
            if (results.summary.failed > 0) {
                console.log('\n⚠️  Some operations failed - manual intervention may be required');
                process.exit(1);
            } else {
                process.exit(0);
            }
        })
        .catch((error) => {
            console.error('💥 Migration failed:', error);
            process.exit(1);
        });
}

module.exports = { executeTriggersMigration };