/**
 * Custom Authentication System for SnappyCards
 * This bypasses Supabase Auth and uses the user_profiles table directly
 * Used as a fallback when Supabase Auth has schema issues
 */

// Custom authentication using user_profiles table
async function customLoginUser(loginData) {
    try {
        // Query user_profiles table directly using Supabase client
        const { data: userProfile, error } = await window.supabaseClient
            .from('user_profiles')
            .select('*')
            .eq('email', loginData.email)
            .eq('stored_password', loginData.password)
            .single();

        if (error) {
            console.error('❌ Custom login error:', error);
            return { success: false, error: 'Invalid email or password' };
        }

        if (!userProfile) {
            return { success: false, error: 'Invalid email or password' };
        }

        // Store user session in localStorage (simple session management)
        const sessionData = {
            user: {
                id: userProfile.id,
                email: userProfile.email,
                user_metadata: {
                    first_name: userProfile.first_name,
                    last_name: userProfile.last_name,
                    user_role: userProfile.user_role,
                    language: 'hu',
                    country: 'HU'
                }
            },
            expires_at: Date.now() + (24 * 60 * 60 * 1000), // 24 hours
            access_token: 'custom_session_' + userProfile.id,
            refresh_token: 'custom_refresh_' + userProfile.id
        };

        localStorage.setItem('custom_supabase_session', JSON.stringify(sessionData));
        
        console.log('✅ Custom login successful:', userProfile.email);
        return { success: true, user: sessionData.user, session: sessionData };

    } catch (error) {
        console.error('❌ Custom login error:', error);
        return { success: false, error: error.message };
    }
}

// Get current user from custom session
async function customGetCurrentUser() {
    try {
        const sessionData = localStorage.getItem('custom_supabase_session');
        
        if (!sessionData) {
            return { success: false, error: 'No session found' };
        }

        const session = JSON.parse(sessionData);
        
        // Check if session is expired
        if (Date.now() > session.expires_at) {
            localStorage.removeItem('custom_supabase_session');
            return { success: false, error: 'Session expired' };
        }

        return { success: true, user: session.user };

    } catch (error) {
        console.error('❌ Custom get user error:', error);
        return { success: false, error: error.message };
    }
}

// Custom logout
async function customLogoutUser() {
    try {
        localStorage.removeItem('custom_supabase_session');
        console.log('✅ Custom logout successful');
        return { success: true };

    } catch (error) {
        console.error('❌ Custom logout error:', error);
        return { success: false, error: error.message };
    }
}

// Check if user is authenticated with custom auth
async function customIsAuthenticated() {
    const result = await customGetCurrentUser();
    return result.success && result.user;
}

// Override the original auth functions with custom ones
function enableCustomAuth() {
    console.log('🔄 Enabling custom authentication fallback...');
    
    // Override the global SnappyAuth object
    if (typeof window !== 'undefined') {
        window.SnappyAuth = {
            login: customLoginUser,
            logout: customLogoutUser,
            getCurrentUser: customGetCurrentUser,
            isAuthenticated: customIsAuthenticated,
            signUp: function() {
                console.warn('⚠️ Sign up not implemented in custom auth');
                return { success: false, error: 'Sign up not available' };
            }
        };

        // Also override individual functions for backward compatibility
        window.loginUser = customLoginUser;
        window.getCurrentUser = customGetCurrentUser;
        window.logoutUser = customLogoutUser;
        window.isAuthenticated = customIsAuthenticated;

        console.log('✅ Custom authentication enabled');
    }
}

// Auto-enable custom auth if Supabase Auth fails
function initCustomAuth() {
    // Test if Supabase Auth is working
    if (window.supabaseClient) {
        window.supabaseClient.auth.getUser()
            .then((result) => {
                if (result.error && result.error.message.includes('Database error')) {
                    console.log('🔧 Supabase Auth error detected, enabling custom auth...');
                    enableCustomAuth();
                }
            })
            .catch((error) => {
                console.log('🔧 Supabase Auth failed, enabling custom auth...');
                enableCustomAuth();
            });
    }
}

// Make functions available globally
if (typeof window !== 'undefined') {
    window.CustomAuth = {
        login: customLoginUser,
        logout: customLogoutUser,
        getCurrentUser: customGetCurrentUser,
        isAuthenticated: customIsAuthenticated,
        enable: enableCustomAuth,
        init: initCustomAuth
    };

    // Auto-initialize on load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initCustomAuth);
    } else {
        initCustomAuth();
    }
}