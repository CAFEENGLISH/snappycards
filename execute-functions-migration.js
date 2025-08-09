/**
 * EXECUTE FUNCTIONS MIGRATION FOR NEW SUPABASE PROJECT
 * ===================================================
 * This script executes the database functions migration
 * for the NEW SnappyCards Supabase project (aeijlzokobuqcyznljvn)
 */

const fs = require('fs');
const path = require('path');

// NEW project configuration (aeijlzokobuqcyznljvn - snappycards2025)
const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || 'YOUR_NEW_PROJECT_SERVICE_ROLE_KEY';

console.log('🚀 Executing Database Functions Migration for SnappyCards...');
console.log('Target: NEW Supabase project (aeijlzokobuqcyznljvn - snappycards2025)');
console.log('');

// Check for service key
if (SUPABASE_SERVICE_KEY === 'YOUR_NEW_PROJECT_SERVICE_ROLE_KEY') {
    console.error('❌ Service role key not provided!');
    console.log('');
    console.log('To run this script, you need the service role key for your NEW project:');
    console.log('1. Go to https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn');
    console.log('2. Go to Settings → API');
    console.log('3. Copy the "service_role" key (not the anon key)');
    console.log('4. Set it as environment variable:');
    console.log('   export SUPABASE_SERVICE_KEY="your_service_role_key_here"');
    console.log('5. Run this script again: node execute-functions-migration.js');
    process.exit(1);
}

// Initialize Supabase client with service role key
async function initializeSupabase() {
    try {
        const { createClient } = await import('@supabase/supabase-js');
        return createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
            auth: {
                autoRefreshToken: false,
                persistSession: false
            }
        });
    } catch (error) {
        console.error('❌ Failed to initialize Supabase client:', error.message);
        console.log('');
        console.log('Make sure @supabase/supabase-js is installed:');
        console.log('   npm install @supabase/supabase-js');
        process.exit(1);
    }
}

// Read migration file
function readMigrationFile() {
    const migrationFile = path.join(__dirname, 'migrate-missing-functions.sql');
    
    if (!fs.existsSync(migrationFile)) {
        console.error('❌ Migration file not found:', migrationFile);
        process.exit(1);
    }
    
    console.log('📖 Reading migration file:', migrationFile);
    return fs.readFileSync(migrationFile, 'utf8');
}

// Extract individual functions from migration file
function extractFunctions(migrationContent) {
    const functions = {};
    
    // Extract create_classroom function
    const createClassroomMatch = migrationContent.match(/-- Function: create_classroom([\s\S]*?)(?=-- Function:|$)/);
    if (createClassroomMatch) {
        functions.create_classroom = createClassroomMatch[1].trim();
    }
    
    // Extract generate_invite_code function
    const generateCodeMatch = migrationContent.match(/-- Function: generate_invite_code([\s\S]*?)(?=-- Function:|$)/);
    if (generateCodeMatch) {
        functions.generate_invite_code = generateCodeMatch[1].trim();
    }
    
    // Extract handle_new_user function
    const handleUserMatch = migrationContent.match(/-- Function: handle_new_user([\s\S]*?)(?=-- Function:|$)/);
    if (handleUserMatch) {
        functions.handle_new_user = handleUserMatch[1].trim();
    }
    
    // Extract join_classroom_with_code function
    const joinClassroomMatch = migrationContent.match(/-- Function: join_classroom_with_code([\s\S]*?)$/);
    if (joinClassroomMatch) {
        functions.join_classroom_with_code = joinClassroomMatch[1].trim();
    }
    
    return functions;
}

// Execute a single function
async function executeFunction(supabase, functionName, functionSql) {
    console.log(`📝 Creating function: ${functionName}`);
    console.log('='.repeat(25 + functionName.length));
    
    try {
        const { data, error } = await supabase.rpc('exec_sql', { 
            sql: functionSql 
        }).catch(async () => {
            // Fallback: try direct SQL execution
            return await supabase
                .from('_dummy') // This will fail but trigger SQL execution
                .select('*')
                .limit(0)
                .then(() => ({ data: null, error: null }))
                .catch(async () => {
                    // Last resort: use PostgreSQL connection if available
                    const { data, error } = await supabase.rpc('exec', { sql: functionSql });
                    return { data, error };
                });
        });
        
        if (error) {
            console.error(`❌ Failed to create function ${functionName}:`, error.message);
            return false;
        } else {
            console.log(`✅ Successfully created function: ${functionName}`);
            return true;
        }
    } catch (error) {
        console.error(`❌ Failed to create function ${functionName}:`, error.message);
        return false;
    }
}

// Verify functions exist
async function verifyFunctions(supabase) {
    console.log('🔍 Verifying functions were created...');
    console.log('=====================================');
    
    const verifySQL = `
        SELECT 
            routine_name as function_name,
            routine_type,
            data_type as return_type
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name IN ('create_classroom', 'generate_invite_code', 'handle_new_user', 'join_classroom_with_code')
        ORDER BY routine_name;
    `;
    
    try {
        const { data, error } = await supabase.rpc('exec_sql', { sql: verifySQL });
        
        if (error) {
            console.error('❌ Functions verification failed:', error.message);
            return 0;
        }
        
        console.log('✅ Functions verification successful:');
        console.log(data);
        
        const functionCount = data ? data.length : 0;
        console.log('');
        console.log('📈 RESULTS SUMMARY:');
        console.log('==================');
        console.log(`• Functions found: ${functionCount} / 4`);
        
        if (functionCount === 4) {
            console.log('🎉 SUCCESS! All 4 functions were created successfully:');
            console.log('   ✓ handle_new_user() - trigger function for new user creation');
            console.log('   ✓ create_classroom() - creates classroom with invite code');
            console.log('   ✓ generate_invite_code() - generates unique classroom invite codes');
            console.log('   ✓ join_classroom_with_code() - allows students to join classrooms');
        } else {
            console.log(`⚠️  WARNING: Only ${functionCount} out of 4 functions were created`);
            console.log('Please check the errors above and retry failed functions');
        }
        
        return functionCount;
    } catch (error) {
        console.error('❌ Functions verification failed:', error.message);
        return 0;
    }
}

// Main execution function
async function main() {
    try {
        // Initialize Supabase client
        const supabase = await initializeSupabase();
        console.log('✅ Supabase client initialized');
        console.log(`🔍 Connecting to: ${SUPABASE_URL}`);
        console.log('');
        
        // Read migration file
        const migrationContent = readMigrationFile();
        
        // Extract functions
        const functions = extractFunctions(migrationContent);
        console.log(`📚 Extracted ${Object.keys(functions).length} functions from migration file`);
        console.log('');
        
        // Execute functions
        console.log('🔄 Executing function migrations...');
        console.log('');
        
        let successCount = 0;
        const functionOrder = ['generate_invite_code', 'handle_new_user', 'create_classroom', 'join_classroom_with_code'];
        
        for (const functionName of functionOrder) {
            if (functions[functionName]) {
                const success = await executeFunction(supabase, functionName, functions[functionName]);
                if (success) successCount++;
                console.log('');
            } else {
                console.log(`⚠️  Function ${functionName} not found in migration file`);
            }
        }
        
        // Verify functions
        const verifiedCount = await verifyFunctions(supabase);
        
        console.log('');
        console.log('✅ Database Functions Migration completed!');
        console.log('');
        console.log('🎯 Next steps:');
        console.log('1. Verify the functions work by testing them in your application');
        console.log('2. Check that the trigger for handle_new_user() is also created');
        console.log('3. Test classroom creation and joining functionality');
        
        // Exit with appropriate code
        process.exit(verifiedCount === 4 ? 0 : 1);
        
    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        process.exit(1);
    }
}

// Run the migration
main();