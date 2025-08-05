/**
 * Central Configuration for SnappyCards
 * All API endpoints, URLs and configuration in one place
 * Usage: <script src="config/supabase.js"></script>
 */

// Environment detection
const isProduction = window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1';

// Central API Configuration
window.SNAPPY_CONFIG = {
    // Supabase
    supabase: {
        url: 'https://ycxqxdhaxehspypqbnpi.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g'
    },
    
    // Backend API
    api: {
        baseUrl: isProduction 
            ? 'https://snappycards-api.onrender.com'
            : 'http://localhost:8080',
        endpoints: {
            register: '/register',
            sendConfirmation: '/send-confirmation',
            adminUpdateTeacher: '/admin/update-teacher',
            adminUpdatePassword: '/admin/update-teacher-password',
            adminUpdateEmail: '/admin/update-teacher-email'
        }
    },
    
    // External APIs
    external: {
        geolocation: 'https://ipapi.co/json/',
        youtube: {
            domains: ['youtube.com', 'youtu.be'],
            embedBase: 'https://www.youtube.com/embed/'
        },
        unsplash: {
            placeholder: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=300&fit=crop&crop=center'
        }
    },
    
    // CDN URLs
    cdn: {
        supabase: 'https://unpkg.com/@supabase/supabase-js@2',
        lucide: 'https://unpkg.com/lucide@latest/dist/umd/lucide.js',
        fonts: 'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap'
    },
    
    // App settings
    app: {
        name: 'SnappyCards',
        defaultLanguage: 'hu',
        defaultCountry: 'HU'
    }
};

// Backwards compatibility
window.SUPABASE_CONFIG = window.SNAPPY_CONFIG.supabase;

// Initialize Supabase client when this script loads
if (typeof window.supabase !== 'undefined') {
    window.supabaseClient = window.supabase.createClient(
        window.SUPABASE_CONFIG.url, 
        window.SUPABASE_CONFIG.anonKey
    );
    console.log('✅ Supabase client initialized from central config');
} else {
    console.warn('⚠️ Supabase library not loaded. Make sure to include @supabase/supabase-js before this script.');
}

// Backwards compatibility - create the old global constants
window.SUPABASE_URL = window.SUPABASE_CONFIG.url;
window.SUPABASE_ANON_KEY = window.SUPABASE_CONFIG.anonKey;