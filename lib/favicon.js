/**
 * SnappyCards Dynamic Favicon Loader
 * Loads favicon from Supabase database
 */

class FaviconManager {
    constructor() {
        this.supabase = null;
        this.currentFavicon = null;
    }

    /**
     * Load and set the active favicon from database
     */
    async loadFavicon() {
        try {
            // Supabase client should already be set by loadFaviconWithRetry
            if (!this.supabase || typeof this.supabase.from !== 'function') {
                console.warn('⚠️ Supabase client not available in loadFavicon, using default');
                this.setDefaultFavicon();
                return;
            }

            // Get active favicon from database
            const { data: favicon, error } = await this.supabase
                .from('favicons')
                .select('data_url, mime_type')
                .eq('is_active', true)
                .single();

            if (error) {
                console.warn('⚠️ Could not load favicon from database:', error.message);
                this.setDefaultFavicon();
                return;
            }

            if (favicon) {
                console.log('🔍 Favicon data found:', {
                    mime_type: favicon.mime_type,
                    data_length: favicon.data_url.length,
                    data_preview: favicon.data_url.substring(0, 50)
                });
                this.setFavicon(favicon.data_url, favicon.mime_type);
                console.log('✅ Favicon loaded from database and set');
            } else {
                console.warn('⚠️ No active favicon found in database');
                this.setDefaultFavicon();
            }
        } catch (error) {
            console.error('❌ Error loading favicon:', error);
            this.setDefaultFavicon();
        }
    }

    /**
     * Set favicon using data URL
     */
    setFavicon(dataUrl, mimeType = 'image/x-icon') {
        console.log('🔧 Setting favicon:', {
            mimeType,
            dataUrlLength: dataUrl.length,
            dataUrlPreview: dataUrl.substring(0, 50)
        });
        
        // Remove ALL existing favicons aggressively
        this.removeFavicon();
        
        // Remove any static favicon links
        const existingIcons = document.querySelectorAll('link[rel*="icon"]');
        existingIcons.forEach(icon => icon.remove());

        // Create new favicon link with cache busting
        const link = document.createElement('link');
        link.rel = 'icon';
        link.type = mimeType;
        link.href = dataUrl + '?t=' + Date.now(); // Cache bust
        
        // Force immediate favicon change
        link.id = 'dynamic-favicon';
        
        // Add to document head
        document.head.appendChild(link);
        this.currentFavicon = link;
        
        // Also try shortcut icon for extra browser compatibility
        const shortcutLink = document.createElement('link');
        shortcutLink.rel = 'shortcut icon';
        shortcutLink.type = mimeType;
        shortcutLink.href = dataUrl + '?t=' + Date.now();
        document.head.appendChild(shortcutLink);
        
        // TEST: Add a simple red square favicon for testing
        setTimeout(() => {
            const testLink = document.createElement('link');
            testLink.rel = 'icon';
            testLink.type = 'image/svg+xml';
            testLink.href = 'data:image/svg+xml;charset=utf-8,%3Csvg xmlns="http://www.w3.org/2000/svg" width="16" height="16"%3E%3Crect width="16" height="16" fill="red"/%3E%3C/svg%3E';
            testLink.id = 'test-favicon';
            document.head.appendChild(testLink);
            console.log('🔴 TEST: Simple red square favicon added for visibility test');
        }, 500);
        
        console.log('📌 Favicon element added to DOM:', {
            rel: link.rel,
            type: link.type,
            href: link.href.substring(0, 50) + '...'
        });
        
        // Force favicon refresh by manipulating the URL
        setTimeout(() => {
            const newUrl = window.location.href.split('?')[0] + '?favicon=' + Date.now();
            window.history.replaceState({}, '', newUrl);
            window.history.replaceState({}, '', window.location.href.split('?')[0]);
        }, 100);
    }

    /**
     * Remove current favicon
     */
    removeFavicon() {
        const existingFavicons = document.querySelectorAll('link[rel="icon"], link[rel="shortcut icon"]');
        existingFavicons.forEach(link => link.remove());
        this.currentFavicon = null;
    }

    /**
     * Set default SVG favicon as fallback
     */
    setDefaultFavicon() {
        const defaultSvg = `data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjMyIiBoZWlnaHQ9IjMyIiByeD0iNCIgZmlsbD0iIzYzNjZmMSIvPgo8cmVjdCB4PSI0IiB5PSI2IiB3aWR0aD0iMjQiIGhlaWdodD0iMTYiIHJ4PSIzIiBmaWxsPSIjZmZmZmZmIiBzdHJva2U9IiNkZGRkZGQiIHN0cm9rZS13aWR0aD0iMC41Ii8+Cjx0ZXh0IHg9IjE2IiB5PSIxOCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjE0IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzYzNjZmMSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiPlM8L3RleHQ+CjxjaXJjbGUgY3g9IjgiIGN5PSIxMCIgcj0iMSIgZmlsbD0iIzYzNjZmMSIvPgo8Y2lyY2xlIGN4PSIyNCIgY3k9IjE4IiByPSIxIiBmaWxsPSIjNjM2NmYxIi8+Cjwvc3ZnPgo=`;
        this.setFavicon(defaultSvg, 'image/svg+xml');
        console.log('✅ Default favicon set');
    }

    /**
     * Initialize favicon loading on page load
     */
    init() {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.loadFaviconWithRetry());
        } else {
            this.loadFaviconWithRetry();
        }
    }

    /**
     * Load favicon with retry mechanism for Supabase initialization
     */
    async loadFaviconWithRetry(maxRetries = 3, delay = 500) {
        for (let i = 0; i < maxRetries; i++) {
            // Try to create Supabase client if library is available
            if (window.supabase && typeof window.supabase.createClient === 'function') {
                try {
                    const supabaseUrl = 'https://ycxqxdhaxehspypqbnpi.supabase.co';
                    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g';
                    
                    this.supabase = window.supabase.createClient(supabaseUrl, supabaseKey);
                    
                    // Make Supabase client globally available to avoid multiple instances
                    window.globalSupabaseClient = this.supabase;
                    
                    if (typeof this.supabase.from === 'function') {
                        await this.loadFavicon();
                        return;
                    }
                } catch (error) {
                    console.error(`❌ Failed to create Supabase client:`, error);
                }
            }
            
            // Fallback: Try to find existing client
            const existingClient = this.findSupabaseClient();
            if (existingClient && typeof existingClient.from === 'function') {
                this.supabase = existingClient;
                console.log(`✅ Found existing Supabase client on attempt ${i + 1}`);
                await this.loadFavicon();
                return;
            }
            
            if (i < maxRetries - 1) {
                console.log(`⏳ Waiting for Supabase to load... (attempt ${i + 1}/${maxRetries})`);
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
        
        console.warn('⚠️ Supabase not available after retries, using default favicon');
        this.setDefaultFavicon();
    }

    /**
     * Try to find Supabase client in various locations
     */
    findSupabaseClient() {
        // Check common global variables where Supabase client might be stored
        const possibleNames = ['supabase', '_supabase', 'supabaseClient'];
        
        for (const name of possibleNames) {
            if (window[name] && typeof window[name].from === 'function') {
                return window[name];
            }
        }
        
        // Check if window.supabase is the library and try to find a created client
        if (window.supabase && window.supabase.createClient) {
            // Look for existing client instances
            for (const key in window) {
                if (window[key] && typeof window[key].from === 'function' && window[key].auth) {
                    return window[key];
                }
            }
        }
        
        return null;
    }
}

// Global favicon manager instance
window.faviconManager = new FaviconManager();

// Auto-initialize with improved timing
document.addEventListener('DOMContentLoaded', () => {
    // Wait a bit for other scripts to load
    setTimeout(() => {
        if (window.faviconManager) {
            window.faviconManager.loadFaviconWithRetry();
        }
    }, 1000); // 1 second delay to let Supabase initialize
});