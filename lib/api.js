/**
 * API Service Layer for SnappyCards
 * Centralized backend communication
 */

// API Service Class
class SnappyAPI {
    constructor() {
        this.baseUrl = window.SNAPPY_CONFIG.api.baseUrl;
        this.endpoints = window.SNAPPY_CONFIG.api.endpoints;
    }

    // Generic API request method
    async request(endpoint, options = {}) {
        const url = this.baseUrl + endpoint;
        const defaultOptions = {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        };

        try {
            const response = await fetch(url, { ...defaultOptions, ...options });
            
            if (!response.ok) {
                throw new Error(`API Error: ${response.status} ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            console.error('API Request failed:', error);
            throw error;
        }
    }

    // Email Services
    async sendConfirmationEmail(email, token) {
        return this.request(this.endpoints.sendConfirmation, {
            method: 'POST',
            body: JSON.stringify({ email, token })
        });
    }

    async sendRegistrationEmail(userData) {
        return this.request(this.endpoints.register, {
            method: 'POST',
            body: JSON.stringify(userData)
        });
    }

    // Admin Services (requires auth token)
    async updateTeacher(teacherData, authToken) {
        return this.request(this.endpoints.adminUpdateTeacher, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify(teacherData)
        });
    }

    async updateTeacherPassword(passwordData, authToken) {
        return this.request(this.endpoints.adminUpdatePassword, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify(passwordData)
        });
    }

    async updateTeacherEmail(emailData, authToken) {
        return this.request(this.endpoints.adminUpdateEmail, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify(emailData)
        });
    }
}

// External API Services
class ExternalAPI {
    constructor() {
        this.config = window.SNAPPY_CONFIG.external;
    }

    // Geolocation service
    async getLocationData() {
        try {
            const response = await fetch(this.config.geolocation);
            if (!response.ok) {
                throw new Error('Geolocation service unavailable');
            }
            return await response.json();
        } catch (error) {
            console.warn('Geolocation failed, using defaults:', error);
            return {
                country_code: window.SNAPPY_CONFIG.app.defaultCountry,
                region: '',
                city: '',
                language: window.SNAPPY_CONFIG.app.defaultLanguage
            };
        }
    }

    // Language detection based on geolocation
    async detectUserLanguage() {
        const locationData = await this.getLocationData();
        
        const languageMap = {
            'HU': 'hu',
            'US': 'en',
            'GB': 'en',
            'DE': 'de',
            'FR': 'fr',
            'ES': 'es',
            'IT': 'it',
            'RO': 'ro',
            'SK': 'sk',
            'AT': 'de',
            'CH': 'de'
        };

        return {
            country: locationData.country_code || window.SNAPPY_CONFIG.app.defaultCountry,
            region: locationData.region || '',
            city: locationData.city || '',
            language: languageMap[locationData.country_code] || window.SNAPPY_CONFIG.app.defaultLanguage
        };
    }

    // YouTube URL processing
    getYouTubeEmbedUrl(url) {
        if (!url.includes('youtube.com') && !url.includes('youtu.be')) {
            return url;
        }

        let videoId = '';
        if (url.includes('youtube.com/watch?v=')) {
            videoId = url.split('v=')[1].split('&')[0];
        } else if (url.includes('youtu.be/')) {
            videoId = url.split('youtu.be/')[1].split('?')[0];
        }

        return videoId ? this.config.youtube.embedBase + videoId : url;
    }

    // Media URL processing
    getMediaPlaceholder(type = 'image') {
        switch (type) {
            case 'image':
            default:
                return this.config.unsplash.placeholder;
        }
    }
}

// Form Validation Services
class ValidationService {
    static validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    static validatePassword(password) {
        const minLength = 8;
        const hasUpperCase = /[A-Z]/.test(password);
        const hasLowerCase = /[a-z]/.test(password);
        const hasNumbers = /\d/.test(password);

        return {
            isValid: password.length >= minLength && hasUpperCase && hasLowerCase && hasNumbers,
            checks: {
                length: password.length >= minLength,
                upperCase: hasUpperCase,
                lowerCase: hasLowerCase,
                numbers: hasNumbers
            },
            strength: this.calculatePasswordStrength(password)
        };
    }

    static calculatePasswordStrength(password) {
        let score = 0;
        if (password.length >= 8) score++;
        if (password.length >= 12) score++;
        if (/[A-Z]/.test(password)) score++;
        if (/[a-z]/.test(password)) score++;
        if (/\d/.test(password)) score++;
        if (/[^A-Za-z0-9]/.test(password)) score++;

        if (score <= 2) return 'weak';
        if (score <= 4) return 'medium';
        return 'strong';
    }

    static validateForm(formData, rules) {
        const errors = {};

        for (const [field, value] of Object.entries(formData)) {
            const rule = rules[field];
            if (!rule) continue;

            if (rule.required && (!value || value.trim() === '')) {
                errors[field] = `${field} is required`;
                continue;
            }

            if (rule.email && !this.validateEmail(value)) {
                errors[field] = 'Invalid email format';
                continue;
            }

            if (rule.password) {
                const validation = this.validatePassword(value);
                if (!validation.isValid) {
                    errors[field] = 'Password must be at least 8 characters with uppercase, lowercase, and numbers';
                }
            }

            if (rule.minLength && value.length < rule.minLength) {
                errors[field] = `Minimum length is ${rule.minLength} characters`;
            }

            if (rule.maxLength && value.length > rule.maxLength) {
                errors[field] = `Maximum length is ${rule.maxLength} characters`;
            }
        }

        return {
            isValid: Object.keys(errors).length === 0,
            errors
        };
    }
}

// Make services globally available
if (typeof window !== 'undefined') {
    window.SnappyAPI = new SnappyAPI();
    window.ExternalAPI = new ExternalAPI();
    window.ValidationService = ValidationService;
    
    console.log('✅ SnappyCards API services loaded');
}