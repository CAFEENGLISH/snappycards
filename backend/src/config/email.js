const { Resend } = require('resend');
require('dotenv').config();

// Verify Resend API key
if (!process.env.RESEND_API_KEY) {
    console.error('❌ RESEND_API_KEY environment variable is required');
    console.error('   Please set your Resend API key:');
    console.error('   export RESEND_API_KEY="your_api_key_here"');
    process.exit(1);
} else {
    console.log('✅ Resend API initialized - Version 2025.01.25');
}

// Resend API Configuration
const resend = new Resend(process.env.RESEND_API_KEY);

module.exports = {
    resend
};