/**
 * TEST FUNCTIONS MIGRATION
 * ======================
 * This script tests that all 4 database functions were created successfully
 * and are accessible in the NEW Supabase project
 */

const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || 'YOUR_SERVICE_KEY_HERE';

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
        process.exit(1);
    }
}

async function testFunctionsExist(supabase) {
    console.log('🔍 Testing Functions Migration Results');
    console.log('=====================================');
    
    const query = `
        SELECT 
            routine_name as function_name,
            routine_type,
            data_type as return_type,
            routine_definition is not null as has_definition
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name IN ('create_classroom', 'generate_invite_code', 'handle_new_user', 'join_classroom_with_code')
        ORDER BY routine_name;
    `;
    
    try {
        const { data, error } = await supabase.rpc('exec_sql', { sql: query });
        
        if (error) {
            console.error('❌ Query failed:', error.message);
            return false;
        }
        
        console.log('📊 Found Functions:');
        console.log('===================');
        
        const expectedFunctions = ['create_classroom', 'generate_invite_code', 'handle_new_user', 'join_classroom_with_code'];
        const foundFunctions = data ? data.map(f => f.function_name) : [];
        
        expectedFunctions.forEach(funcName => {
            const found = foundFunctions.includes(funcName);
            console.log(`${found ? '✅' : '❌'} ${funcName}${found ? ' - FOUND' : ' - MISSING'}`);
        });
        
        console.log('');
        console.log(`📈 Results: ${foundFunctions.length} / ${expectedFunctions.length} functions found`);
        
        if (foundFunctions.length === expectedFunctions.length) {
            console.log('🎉 SUCCESS! All functions are present and ready to use');
        } else {
            console.log('⚠️  WARNING: Some functions are missing. Please re-run the migration.');
        }
        
        return foundFunctions.length === expectedFunctions.length;
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        return false;
    }
}

async function testFunctionSignatures(supabase) {
    console.log('');
    console.log('🔬 Testing Function Signatures');
    console.log('==============================');
    
    const signatureQuery = `
        SELECT 
            routine_name,
            string_agg(
                parameter_name || ' ' || data_type || 
                CASE WHEN parameter_default IS NOT NULL 
                     THEN ' DEFAULT ' || parameter_default 
                     ELSE '' END,
                ', ' ORDER BY ordinal_position
            ) as parameters
        FROM information_schema.routines r
        LEFT JOIN information_schema.parameters p 
            ON r.routine_name = p.routine_name 
            AND r.routine_schema = p.routine_schema
            AND parameter_mode = 'IN'
        WHERE r.routine_schema = 'public' 
        AND r.routine_name IN ('create_classroom', 'generate_invite_code', 'handle_new_user', 'join_classroom_with_code')
        GROUP BY r.routine_name
        ORDER BY r.routine_name;
    `;
    
    try {
        const { data, error } = await supabase.rpc('exec_sql', { sql: signatureQuery });
        
        if (error) {
            console.error('❌ Signature query failed:', error.message);
            return false;
        }
        
        if (data && data.length > 0) {
            data.forEach(func => {
                console.log(`📝 ${func.routine_name}(${func.parameters || 'no parameters'})`);
            });
        } else {
            console.log('⚠️  No function signatures found');
        }
        
        return true;
        
    } catch (error) {
        console.error('❌ Signature test failed:', error.message);
        return false;
    }
}

async function testSimpleFunctionCall(supabase) {
    console.log('');
    console.log('🧪 Testing Simple Function Call');
    console.log('===============================');
    
    try {
        // Test generate_invite_code function (simplest one)
        const { data, error } = await supabase.rpc('generate_invite_code', { length: 6 });
        
        if (error) {
            console.error('❌ Function call failed:', error.message);
            return false;
        }
        
        if (data && typeof data === 'string' && data.length === 6) {
            console.log(`✅ generate_invite_code() works! Generated code: ${data}`);
            return true;
        } else {
            console.log('⚠️  Function returned unexpected result:', data);
            return false;
        }
        
    } catch (error) {
        console.error('❌ Function call test failed:', error.message);
        return false;
    }
}

async function main() {
    console.log('🚀 Testing Database Functions Migration');
    console.log('Target: NEW Supabase project (aeijlzokobuqcyznljvn)');
    console.log('');
    
    if (SUPABASE_SERVICE_KEY === 'YOUR_SERVICE_KEY_HERE') {
        console.error('❌ Service role key not set!');
        console.log('Run: export SUPABASE_SERVICE_KEY="your_service_role_key_here"');
        process.exit(1);
    }
    
    const supabase = await initializeSupabase();
    console.log('✅ Connected to Supabase');
    console.log('');
    
    // Run tests
    const functionsExist = await testFunctionsExist(supabase);
    const signaturesOK = await testFunctionSignatures(supabase);
    const callWorks = await testSimpleFunctionCall(supabase);
    
    console.log('');
    console.log('📋 TEST SUMMARY');
    console.log('==============');
    console.log(`Functions exist: ${functionsExist ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`Signatures OK: ${signaturesOK ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`Function calls work: ${callWorks ? '✅ PASS' : '❌ FAIL'}`);
    
    const allTestsPassed = functionsExist && signaturesOK && callWorks;
    
    console.log('');
    if (allTestsPassed) {
        console.log('🎉 ALL TESTS PASSED! Functions migration was successful.');
    } else {
        console.log('⚠️  Some tests failed. Please check the migration and retry.');
    }
    
    process.exit(allTestsPassed ? 0 : 1);
}

main();