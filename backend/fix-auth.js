const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Supabase Admin Configuration
const supabaseUrl = process.env.SUPABASE_URL || 'https://ycxqxdhaxehspypqbnpi.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzIwMzAzMSwiZXhwIjoyMDY4Nzc5MDMxfQ.0jZl6iSSz0BV9TlQhWOE5utuv71YetOWhsU0vQOdagM';
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

const userEmail = 'vidamkos@gmail.com';
const userPassword = 'Palacs1nta';
const userId = '9802312d-e7ce-4005-994b-ee9437fb5326';

async function fixAuthentication() {
    console.log('🔧 Starting authentication fix process...');
    
    // Step 1: Check if user exists in auth.users
    console.log('🔍 Step 1: Checking if user exists in auth.users...');
    try {
        const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers();
        
        if (listError) {
            console.error('❌ Error listing users:', listError.message);
            console.log('📋 This confirms the database error when querying auth schema.');
        } else {
            console.log(`✅ Successfully connected to auth.users. Found ${users.users.length} users.`);
            const targetUser = users.users.find(u => u.email === userEmail);
            if (targetUser) {
                console.log('✅ User already exists in auth.users:', {
                    id: targetUser.id,
                    email: targetUser.email,
                    email_confirmed_at: targetUser.email_confirmed_at
                });
                return;
            } else {
                console.log('⚠️ User does NOT exist in auth.users - will create.');
            }
        }
    } catch (error) {
        console.error('❌ Critical error accessing auth.users:', error.message);
    }

    // Step 2: Create user in auth.users
    console.log('🔧 Step 2: Creating user in auth.users...');
    try {
        const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
            email: userEmail,
            password: userPassword,
            user_metadata: {
                first_name: 'Vidam',
                user_role: 'student'
            },
            email_confirm: true
        });

        if (createError) {
            console.error('❌ Failed to create user in auth.users:', createError.message);
        } else {
            console.log('✅ Successfully created user in auth.users:', {
                id: newUser.user.id,
                email: newUser.user.email,
                email_confirmed_at: newUser.user.email_confirmed_at
            });
        }
    } catch (error) {
        console.error('❌ Error creating user:', error.message);
    }

    // Step 3: Test authentication
    console.log('🔧 Step 3: Testing authentication...');
    try {
        // Create a regular client (not admin) to test signin
        const regularClient = createClient(supabaseUrl, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g');
        
        const { data, error } = await regularClient.auth.signInWithPassword({
            email: userEmail,
            password: userPassword
        });

        if (error) {
            console.error('❌ Authentication test failed:', error.message);
            console.log('   This might indicate the user creation didn\'t work properly.');
        } else {
            console.log('✅ Authentication test successful!');
            console.log('   User can now login with the credentials.');
            
            // Test profile fetch
            const { data: profile, error: profileError } = await regularClient
                .from('user_profiles')
                .select('user_role, first_name, email')
                .eq('id', data.user.id)
                .single();
                
            if (profileError) {
                console.error('⚠️ Profile fetch failed:', profileError.message);
                console.log('   This suggests RLS policies might need adjustment.');
            } else {
                console.log('✅ Profile fetch successful:', profile);
            }
        }
    } catch (error) {
        console.error('❌ Authentication test error:', error.message);
    }

    // Step 4: Check RLS policies
    console.log('🔧 Step 4: Checking RLS policies on user_profiles...');
    try {
        const { data: policies, error: policyError } = await supabaseAdmin
            .rpc('get_policies', { table_name: 'user_profiles' });
            
        if (policyError) {
            console.error('❌ Cannot fetch RLS policies:', policyError.message);
        } else {
            console.log('✅ RLS policies fetched:', policies);
        }
    } catch (error) {
        console.log('⚠️ RLS policy check skipped (RPC might not exist)');
    }
    
    console.log('🎯 Authentication fix process completed!');
}

fixAuthentication().catch(console.error);