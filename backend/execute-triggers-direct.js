#!/usr/bin/env node
/**
 * Direct Triggers Migration Execution
 * Executes triggers and functions directly using Supabase client
 */

const { createClient } = require('@supabase/supabase-js');

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
    
    // Execute each statement using direct HTTP requests to PostgreSQL REST API
    for (let i = 0; i < sqlStatements.length; i++) {
        const statement = sqlStatements[i];
        console.log(`⚡ [${i + 1}/${sqlStatements.length}] ${statement.name}`);
        
        try {
            // Use Supabase's PostgREST API for direct SQL execution
            const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                    'apikey': SUPABASE_ANON_KEY,
                    'Prefer': 'return=minimal'
                },
                body: JSON.stringify({
                    sql: statement.sql
                })
            });
            
            if (response.ok) {
                console.log('✅ Executed successfully');
                successCount++;
                results.push({
                    operation: statement.name,
                    status: 'success'
                });
            } else {
                const errorText = await response.text();
                throw new Error(`HTTP ${response.status}: ${errorText}`);
            }
            
        } catch (error) {
            console.error(`❌ Failed: ${error.message}`);
            errorCount++;
            results.push({
                operation: statement.name,
                status: 'error',
                error: error.message
            });
            
            // Continue with other operations even if one fails
            continue;
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
    console.log('🔍 Testing database connection and basic functionality...');
    
    try {
        // Test basic database connection
        const { data: testData, error: testError } = await supabase
            .from('user_profiles')
            .select('id', { count: 'exact', head: true });
            
        if (testError) {
            console.log('⚠️  Cannot access user_profiles table:', testError.message);
        } else {
            console.log('✅ Database connection confirmed');
            console.log('✅ user_profiles table accessible');
        }
        
        // Try to access information about triggers (this might not work with anon key)
        console.log('\n📋 Expected results from migration:');
        console.log('   ✅ handle_new_user() function created');
        console.log('   ✅ update_updated_at_column() function created');
        console.log('   ✅ on_auth_user_created trigger created on auth.users');
        console.log('   ✅ update_user_profiles_updated_at trigger created on user_profiles');
        
        console.log('\n💡 To verify triggers are working:');
        console.log('   1. Create a new user via Supabase Auth');
        console.log('   2. Check if user_profiles record is automatically created');
        console.log('   3. Update a user_profiles record and check if updated_at changes');
        
    } catch (error) {
        console.log('⚠️  Limited verification due to permissions:', error.message);
        console.log('💡 Please verify manually in Supabase Dashboard');
    }
}

// Execute if called directly
if (require.main === module) {
    executeTriggersMigration()
        .then((results) => {
            console.log('\n🎉 Triggers migration execution completed!');
            console.log('\n📋 NEXT STEPS FOR VERIFICATION:');
            console.log('1. Go to Supabase Dashboard > Project Settings');
            console.log('2. Navigate to Database > Functions to verify functions exist');
            console.log('3. Navigate to Database > Triggers to verify triggers exist');
            console.log('4. Test user registration to ensure automatic profile creation');
            console.log('5. Test profile updates to ensure timestamp updates work');
            
            if (results.summary.failed > 0) {
                console.log('\n⚠️  Some operations failed - please check Supabase Dashboard');
                console.log('   You may need to execute the failed operations manually');
            }
            
            console.log('\n📊 FINAL SUMMARY:');
            console.log(`   Triggers expected: 2`);
            console.log(`   Functions expected: 2`);
            console.log(`   Total operations: ${results.summary.total}`);
            console.log(`   Successful: ${results.summary.successful}`);
            console.log(`   Failed: ${results.summary.failed}`);
            
            process.exit(results.summary.failed > 0 ? 1 : 0);
        })
        .catch((error) => {
            console.error('💥 Migration failed:', error);
            process.exit(1);
        });
}

module.exports = { executeTriggersMigration };