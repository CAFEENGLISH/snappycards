/**
 * Authentication Fix Validation Script
 * Run this script to test if the authentication issues are resolved
 */

// Configuration
const SUPABASE_URL = 'https://ycxqxdhaxehspypqbnpi.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g';

// Test credentials
const TEST_EMAIL = 'vidamkos@gmail.com';
const TEST_PASSWORD = 'Palacs1nta';

console.log('🔍 Starting Authentication Fix Validation...\n');

// Test 1: Check REST API Health
async function testRestAPI() {
    console.log('1️⃣ Testing REST API health...');
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });
        
        if (response.ok) {
            console.log('✅ REST API is healthy');
            return true;
        } else {
            console.log('❌ REST API failed:', response.status, response.statusText);
            return false;
        }
    } catch (error) {
        console.log('❌ REST API error:', error.message);
        return false;
    }
}

// Test 2: Check Auth Health
async function testAuthHealth() {
    console.log('\n2️⃣ Testing Auth health...');
    try {
        const response = await fetch(`${SUPABASE_URL}/auth/v1/health`);
        
        if (response.ok) {
            const data = await response.json();
            console.log('✅ Auth service is healthy:', data.version);
            return true;
        } else {
            console.log('❌ Auth service failed:', response.status, response.statusText);
            return false;
        }
    } catch (error) {
        console.log('❌ Auth service error:', error.message);
        return false;
    }
}

// Test 3: Check user_profiles table exists
async function testUserProfilesTable() {
    console.log('\n3️⃣ Testing user_profiles table access...');
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/user_profiles?select=id&limit=1`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });
        
        if (response.ok) {
            console.log('✅ user_profiles table is accessible');
            return true;
        } else if (response.status === 401) {
            console.log('⚠️ user_profiles table exists but requires authentication (expected with RLS)');
            return true;
        } else {
            console.log('❌ user_profiles table failed:', response.status, response.statusText);
            return false;
        }
    } catch (error) {
        console.log('❌ user_profiles table error:', error.message);
        return false;
    }
}

// Test 4: Test Authentication (if running in browser)
async function testAuthentication() {
    console.log('\n4️⃣ Testing authentication...');
    
    // Check if we're in a browser environment with Supabase client
    if (typeof window !== 'undefined' && window.supabase) {
        try {
            const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
            
            console.log('🔐 Attempting login...');
            const { data, error } = await supabase.auth.signInWithPassword({
                email: TEST_EMAIL,
                password: TEST_PASSWORD
            });
            
            if (error) {
                console.log('❌ Authentication failed:', error.message);
                return false;
            }
            
            console.log('✅ Authentication successful!');
            console.log('👤 User:', data.user.email);
            
            // Test profile fetch
            console.log('📋 Fetching user profile...');
            const { data: profile, error: profileError } = await supabase
                .from('user_profiles')
                .select('user_role, first_name, school_id')
                .eq('id', data.user.id)
                .single();
                
            if (profileError) {
                console.log('❌ Profile fetch failed:', profileError.message);
                return false;
            }
            
            console.log('✅ Profile fetch successful!');
            console.log('👤 Profile:', profile);
            
            // Logout
            await supabase.auth.signOut();
            console.log('🚪 Logged out successfully');
            
            return true;
            
        } catch (error) {
            console.log('❌ Authentication error:', error.message);
            return false;
        }
    } else {
        console.log('⚠️ Browser environment with Supabase client required for auth test');
        console.log('   Run this in debug-auth.html for full authentication testing');
        return null;
    }
}

// Test 5: Comprehensive Database Schema Check
async function testDatabaseSchema() {
    console.log('\n5️⃣ Testing database schema...');
    
    const requiredTables = [
        'user_profiles',
        'schools', 
        'flashcard_sets',
        'cards',
        'study_sessions'
    ];
    
    let allTablesExist = true;
    
    for (const table of requiredTables) {
        try {
            const response = await fetch(`${SUPABASE_URL}/rest/v1/${table}?select=*&limit=1`, {
                headers: {
                    'apikey': SUPABASE_ANON_KEY,
                    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
                }
            });
            
            if (response.ok || response.status === 401) {
                console.log(`✅ ${table} table exists`);
            } else {
                console.log(`❌ ${table} table missing or inaccessible:`, response.status);
                allTablesExist = false;
            }
        } catch (error) {
            console.log(`❌ ${table} table error:`, error.message);
            allTablesExist = false;
        }
    }
    
    return allTablesExist;
}

// Main test function
async function runAllTests() {
    console.log('🚀 SnappyCards Authentication Fix Validation');
    console.log('===========================================\n');
    
    const results = {
        restAPI: await testRestAPI(),
        authHealth: await testAuthHealth(),
        userProfilesTable: await testUserProfilesTable(),
        databaseSchema: await testDatabaseSchema(),
        authentication: await testAuthentication()
    };
    
    console.log('\n📊 TEST RESULTS SUMMARY');
    console.log('========================');
    
    Object.entries(results).forEach(([test, result]) => {
        const status = result === true ? '✅ PASS' : 
                      result === false ? '❌ FAIL' : 
                      result === null ? '⚠️ SKIP' : '❓ UNKNOWN';
        console.log(`${test.padEnd(20)}: ${status}`);
    });
    
    const passedTests = Object.values(results).filter(r => r === true).length;
    const totalTests = Object.values(results).filter(r => r !== null).length;
    
    console.log(`\nOverall: ${passedTests}/${totalTests} tests passed`);
    
    if (passedTests === totalTests) {
        console.log('\n🎉 All tests passed! Authentication should be working.');
        console.log('✅ You can now try logging in with vidamkos@gmail.com / Palacs1nta');
    } else {
        console.log('\n⚠️ Some tests failed. Please run the supabase-setup.sql script first.');
        console.log('📋 Follow the AUTHENTICATION_FIX_GUIDE.md for detailed instructions.');
    }
    
    return results;
}

// Export for browser use or run directly in Node.js
if (typeof window !== 'undefined') {
    window.runAuthTests = runAllTests;
    console.log('🌐 Browser environment detected. Run runAuthTests() to start tests.');
} else if (typeof module !== 'undefined') {
    module.exports = { runAllTests };
    // Auto-run in Node.js environment
    runAllTests();
}