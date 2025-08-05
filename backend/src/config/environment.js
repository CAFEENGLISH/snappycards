require('dotenv').config();

// Frontend and Backend URLs (global scope for use in multiple endpoints)
const frontendUrl = process.env.FRONTEND_URL || 
    (process.env.NODE_ENV === 'production' 
        ? 'https://snappycards.netlify.app' 
        : 'http://localhost:3000');

const backendUrl = process.env.BACKEND_URL || 
    (process.env.NODE_ENV === 'production' 
        ? 'https://snappycards-api.onrender.com' 
        : 'http://localhost:8080');

const PORT = process.env.PORT || 8080;

module.exports = {
    frontendUrl,
    backendUrl,
    PORT,
    NODE_ENV: process.env.NODE_ENV || 'development'
};