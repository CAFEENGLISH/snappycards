const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Import configurations
const { PORT } = require('./config/environment');

// Import routes
const publicRoutes = require('./routes/public');
const adminRoutes = require('./routes/admin');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/', publicRoutes);
app.use('/admin', adminRoutes);

// Start server
app.listen(PORT, () => {
    console.log(`🚀 SnappyCards API Server running on port ${PORT}`);
    console.log(`📧 Email Provider: Resend API`);
    console.log(`📬 From: noreply@snappycards.io`);
    console.log(`🎯 Endpoints: /register, /send-confirmation, /verify, /verify`);
    console.log(`🏫 Admin Endpoints: /admin/update-teacher, /admin/update-teacher-email, /admin/update-teacher-password`);
});

module.exports = app;