/**
 * Helper utilities for SnappyCards
 * Common functions used across the application
 */

// DOM utilities
const SnappyDOM = {
    // Safe element selection
    $(selector) {
        return document.querySelector(selector);
    },
    
    $$(selector) {
        return document.querySelectorAll(selector);
    },
    
    // Show/hide elements
    show(element) {
        if (typeof element === 'string') element = this.$(element);
        if (element) element.style.display = 'block';
    },
    
    hide(element) {
        if (typeof element === 'string') element = this.$(element);
        if (element) element.style.display = 'none';
    },
    
    // Add/remove classes safely
    addClass(element, className) {
        if (typeof element === 'string') element = this.$(element);
        if (element) element.classList.add(className);
    },
    
    removeClass(element, className) {
        if (typeof element === 'string') element = this.$(element);
        if (element) element.classList.remove(className);
    },
    
    // Set text content safely
    setText(element, text) {
        if (typeof element === 'string') element = this.$(element);
        if (element) element.textContent = text;
    }
};

// Loading state management
const SnappyLoading = {
    // Show loading spinner
    show(element, message = 'Betöltés...') {
        if (typeof element === 'string') element = SnappyDOM.$(element);
        if (element) {
            element.innerHTML = `
                <div class="loading-spinner">
                    <div class="spinner"></div>
                    <span>${message}</span>
                </div>
            `;
            SnappyDOM.addClass(element, 'loading');
        }
    },
    
    // Hide loading spinner
    hide(element) {
        if (typeof element === 'string') element = SnappyDOM.$(element);
        if (element) {
            SnappyDOM.removeClass(element, 'loading');
        }
    }
};

// Error handling
const SnappyError = {
    // Show error message
    show(element, message, type = 'error') {
        if (typeof element === 'string') element = SnappyDOM.$(element);
        if (element) {
            const icon = type === 'error' ? '❌' : type === 'warning' ? '⚠️' : 'ℹ️';
            element.innerHTML = `
                <div class="error-message ${type}">
                    <span class="error-icon">${icon}</span>
                    <span class="error-text">${message}</span>
                </div>
            `;
            SnappyDOM.addClass(element, 'has-error');
        }
    },
    
    // Show success message
    success(element, message) {
        if (typeof element === 'string') element = SnappyDOM.$(element);
        if (element) {
            element.innerHTML = `
                <div class="success-message">
                    <span class="success-icon">✅</span>
                    <span class="success-text">${message}</span>
                </div>
            `;
            SnappyDOM.addClass(element, 'has-success');
        }
    },
    
    // Clear error/success states
    clear(element) {
        if (typeof element === 'string') element = SnappyDOM.$(element);
        if (element) {
            SnappyDOM.removeClass(element, 'has-error');
            SnappyDOM.removeClass(element, 'has-success');
            SnappyDOM.removeClass(element, 'loading');
        }
    }
};

// Form utilities
const SnappyForm = {
    // Get form data as object
    getData(form) {
        if (typeof form === 'string') form = SnappyDOM.$(form);
        if (!form) return {};
        
        const formData = new FormData(form);
        const data = {};
        for (let [key, value] of formData.entries()) {
            data[key] = value;
        }
        return data;
    },
    
    // Validate email
    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    },
    
    // Validate password strength
    validatePassword(password) {
        const minLength = 8;
        const hasUpperCase = /[A-Z]/.test(password);
        const hasLowerCase = /[a-z]/.test(password);
        const hasNumbers = /\d/.test(password);
        
        const strength = {
            isValid: password.length >= minLength && hasUpperCase && hasLowerCase && hasNumbers,
            length: password.length >= minLength,
            upperCase: hasUpperCase,
            lowerCase: hasLowerCase,
            numbers: hasNumbers
        };
        
        return strength;
    }
};

// Storage utilities
const SnappyStorage = {
    // LocalStorage with JSON support
    set(key, value) {
        try {
            localStorage.setItem(key, JSON.stringify(value));
            return true;
        } catch (error) {
            console.warn('LocalStorage set failed:', error);
            return false;
        }
    },
    
    get(key, defaultValue = null) {
        try {
            const item = localStorage.getItem(key);
            return item ? JSON.parse(item) : defaultValue;
        } catch (error) {
            console.warn('LocalStorage get failed:', error);
            return defaultValue;
        }
    },
    
    remove(key) {
        try {
            localStorage.removeItem(key);
            return true;
        } catch (error) {
            console.warn('LocalStorage remove failed:', error);
            return false;
        }
    },
    
    clear() {
        try {
            localStorage.clear();
            return true;
        } catch (error) {
            console.warn('LocalStorage clear failed:', error);
            return false;
        }
    }
};

// Make utilities globally available
if (typeof window !== 'undefined') {
    window.SnappyDOM = SnappyDOM;
    window.SnappyLoading = SnappyLoading;
    window.SnappyError = SnappyError;
    window.SnappyForm = SnappyForm;
    window.SnappyStorage = SnappyStorage;
    
    // Shorthand aliases
    window.$ = SnappyDOM.$;
    window.$$ = SnappyDOM.$$;
    
    console.log('✅ SnappyCards helper utilities loaded');
}