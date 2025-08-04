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
            // Ensure Supabase is available
            if (!this.supabase) {
                this.supabase = window.supabase;
            }

            if (!this.supabase || typeof this.supabase.from !== 'function') {
                console.warn('⚠️ Supabase not available, using default favicon');
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
                this.setFavicon(favicon.data_url, favicon.mime_type);
                console.log('✅ Favicon loaded from database');
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
        // Remove existing favicon
        this.removeFavicon();

        // Create new favicon link
        const link = document.createElement('link');
        link.rel = 'icon';
        link.type = mimeType;
        link.href = dataUrl;
        
        // Add to document head
        document.head.appendChild(link);
        this.currentFavicon = link;
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
            if (window.supabase && typeof window.supabase.from === 'function') {
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