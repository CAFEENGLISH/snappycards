const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { PORT } = require('./config/environment');
const publicRoutes = require('./routes/public');
const adminRoutes = require('./routes/admin');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// ---- Health endpoint LEGELŐL, hogy semmi ne nyelje el ----
app.get('/health', (_req, res) => {
  res.status(200).json({
    ok: true,
    service: 'snappycards-backend',
    env: process.env.NODE_ENV || 'development',
    stage: process.env.STAGE || process.env.NEXT_PUBLIC_ENV || 'local',
    supabase: process.env.SUPABASE_URL || 'missing'
  });
});

// ---- Routes ezután jönnek ----
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