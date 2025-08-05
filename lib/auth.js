/**
 * Authentication utilities for SnappyCards
 * Converted from TypeScript to JavaScript for direct HTML integration
 */

// Sign up new user
async function signUpUser(signUpData) {
    try {
        // Get location and language if not provided
        let { language, country } = signUpData;
        if (!language || !country) {
            const location = await getLocationFromIP();
            language = language || location.language;
            country = country || location.country;
        }

        // Use the global supabase client from config
        const { data: authData, error: signUpError } = await window.supabaseClient.auth.signUp({
            email: signUpData.email,
            password: signUpData.password,
            options: {
                data: {
                    first_name: signUpData.firstName,
                    language: language,
                    country: country
                }
            }
        });

        if (signUpError) {
            throw signUpError;
        }

        console.log('✅ User signed up successfully:', authData.user?.email);
        return { success: true, user: authData.user };

    } catch (error) {
        console.error('❌ Sign up error:', error);
        return { success: false, error: error.message };
    }
}

// Log in existing user
async function loginUser(loginData) {
    try {
        const { data: authData, error: loginError } = await window.supabaseClient.auth.signInWithPassword({
            email: loginData.email,
            password: loginData.password
        });

        if (loginError) {
            throw loginError;
        }

        console.log('✅ User logged in successfully:', authData.user?.email);
        return { success: true, user: authData.user };

    } catch (error) {
        console.error('❌ Login error:', error);
        return { success: false, error: error.message };
    }
}

// Log out current user
async function logoutUser() {
    try {
        const { error } = await window.supabaseClient.auth.signOut();
        
        if (error) {
            throw error;
        }

        console.log('✅ User logged out successfully');
        return { success: true };

    } catch (error) {
        console.error('❌ Logout error:', error);
        return { success: false, error: error.message };
    }
}

// Get current user session
async function getCurrentUser() {
    try {
        const { data: { user }, error } = await window.supabaseClient.auth.getUser();
        
        if (error) {
            throw error;
        }

        return { success: true, user };

    } catch (error) {
        console.error('❌ Get user error:', error);
        return { success: false, error: error.message };
    }
}

// Check if user is authenticated
async function isAuthenticated() {
    const result = await getCurrentUser();
    return result.success && result.user;
}

// Simple geolocation function (converted from geolocation.ts)
async function getLocationFromIP() {
    try {
        const response = await fetch('https://ipapi.co/json/');
        const data = await response.json();
        
        // Language mapping based on country
        const languageMap = {
            'HU': 'hu', // Hungary
            'US': 'en', // United States  
            'GB': 'en', // United Kingdom
            'DE': 'de', // Germany
            'FR': 'fr', // France
            'ES': 'es', // Spain
            'IT': 'it', // Italy
            'RO': 'ro', // Romania
            'SK': 'sk', // Slovakia
            'AT': 'de', // Austria
            'CH': 'de', // Switzerland
        };

        return {
            country: data.country_code || 'US',
            region: data.region || '',
            city: data.city || '',
            language: languageMap[data.country_code] || 'en'
        };
    } catch (error) {
        console.warn('⚠️ Geolocation failed, using defaults:', error);
        return {
            country: 'US',
            region: '',
            city: '',
            language: 'en'
        };
    }
}

// Make functions globally available
if (typeof window !== 'undefined') {
    window.SnappyAuth = {
        signUp: signUpUser,
        login: loginUser,
        logout: logoutUser,
        getCurrentUser,
        isAuthenticated,
        getLocationFromIP
    };
    
    console.log('✅ SnappyAuth utilities loaded');
}