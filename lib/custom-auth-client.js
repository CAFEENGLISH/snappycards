/**
 * Custom Authentication Client for SnappyCards
 * Bypasses broken Supabase Auth and uses our custom backend API
 * Compatible with existing Supabase Auth API calls
 */

class CustomAuthClient {
    constructor(apiBaseUrl) {
        this.apiBaseUrl = apiBaseUrl;
        this.currentUser = null;
        this.currentSession = null;
        this.storage = window.localStorage;
        
        // Try to restore session from localStorage
        this.restoreSession();
    }

    /**
     * Sign in with email and password
     * Compatible with: supabase.auth.signInWithPassword()
     */
    async signInWithPassword({ email, password }) {
        try {
            console.log('🔧 Using custom auth - bypassing broken Supabase Auth');
            
            const response = await fetch(`${this.apiBaseUrl}/custom-login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ email, password })
            });

            const result = await response.json();

            if (!response.ok || !result.success) {
                throw new Error(result.error || 'Authentication failed');
            }

            // Store session data
            this.currentUser = result.auth.user;
            this.currentSession = result.auth.session;
            
            // Save to localStorage
            this.storage.setItem('snappy_auth_user', JSON.stringify(this.currentUser));
            this.storage.setItem('snappy_auth_session', JSON.stringify(this.currentSession));

            console.log('✅ Custom auth successful - user logged in');

            // Return format compatible with Supabase
            return {
                data: {
                    user: this.currentUser,
                    session: this.currentSession
                },
                error: null
            };

        } catch (error) {
            console.error('❌ Custom auth failed:', error.message);
            return {
                data: {
                    user: null,
                    session: null
                },
                error: { message: error.message }
            };
        }
    }

    /**
     * Get current user
     * Compatible with: supabase.auth.getUser()
     */
    async getUser() {
        if (this.currentUser && this.isSessionValid()) {
            return {
                data: { user: this.currentUser },
                error: null
            };
        }

        // Session expired or doesn't exist
        this.signOut();
        return {
            data: { user: null },
            error: { message: 'No user session' }
        };
    }

    /**
     * Get current session
     * Compatible with: supabase.auth.getSession()
     */
    async getSession() {
        if (this.currentSession && this.isSessionValid()) {
            return {
                data: { session: this.currentSession },
                error: null
            };
        }

        return {
            data: { session: null },
            error: null
        };
    }

    /**
     * Sign out
     * Compatible with: supabase.auth.signOut()
     */
    async signOut() {
        this.currentUser = null;
        this.currentSession = null;
        
        // Clear localStorage
        this.storage.removeItem('snappy_auth_user');
        this.storage.removeItem('snappy_auth_session');
        
        console.log('🔓 User signed out');
        
        return {
            error: null
        };
    }

    /**
     * Check if current session is valid (not expired)
     */
    isSessionValid() {
        if (!this.currentSession || !this.currentSession.access_token) {
            return false;
        }

        // For our simple session token, decode timestamp and check if it's less than 24 hours old
        try {
            const decoded = atob(this.currentSession.access_token);
            const parts = decoded.split(':');
            if (parts.length >= 3) {
                const timestamp = parseInt(parts[2]);
                const hoursSinceLogin = (Date.now() - timestamp) / (1000 * 60 * 60);
                return hoursSinceLogin < 24; // Session valid for 24 hours
            }
        } catch (error) {
            console.error('Error checking session validity:', error);
        }
        
        return false;
    }

    /**
     * Restore session from localStorage
     */
    restoreSession() {
        try {
            const storedUser = this.storage.getItem('snappy_auth_user');
            const storedSession = this.storage.getItem('snappy_auth_session');

            if (storedUser && storedSession) {
                this.currentUser = JSON.parse(storedUser);
                this.currentSession = JSON.parse(storedSession);

                if (this.isSessionValid()) {
                    console.log('✅ Custom auth session restored');
                } else {
                    console.log('⚠️ Stored session expired, clearing...');
                    this.signOut();
                }
            }
        } catch (error) {
            console.error('Error restoring session:', error);
            this.signOut();
        }
    }

    /**
     * Auth state change listener (simplified version)
     * Compatible with: supabase.auth.onAuthStateChange()
     */
    onAuthStateChange(callback) {
        // For simplicity, we'll just call the callback immediately with current state
        setTimeout(() => {
            callback('SIGNED_IN', this.currentSession);
        }, 0);

        // Return unsubscribe function
        return {
            data: {
                subscription: {
                    unsubscribe: () => {
                        console.log('Auth state listener unsubscribed');
                    }
                }
            }
        };
    }
}

// Create a Supabase-compatible client wrapper
function createCustomSupabaseClient(apiBaseUrl, anonKey) {
    const authClient = new CustomAuthClient(apiBaseUrl);
    
    return {
        auth: authClient,
        // Add other Supabase methods as needed
        from: (table) => {
            // This would need to be implemented if you want to use .from() queries
            // For now, just return a placeholder
            console.warn('Custom client .from() not fully implemented. Use direct API calls.');
            return {
                select: () => Promise.resolve({ data: [], error: null }),
                insert: () => Promise.resolve({ data: [], error: null }),
                update: () => Promise.resolve({ data: [], error: null }),
                delete: () => Promise.resolve({ data: [], error: null })
            };
        }
    };
}

// Global exports
window.CustomAuthClient = CustomAuthClient;
window.createCustomSupabaseClient = createCustomSupabaseClient;

console.log('✅ Custom Auth Client loaded - ready to bypass broken Supabase Auth');