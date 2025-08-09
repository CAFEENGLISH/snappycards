const express = require('express');
const { Resend } = require('resend');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Resend API Configuration
const resend = new Resend(process.env.RESEND_API_KEY);

// Supabase Admin Configuration - NEW PROJECT
const supabaseUrl = process.env.SUPABASE_URL || 'https://aeijlzokobuqcyznljvn.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDU2NjA1NiwiZXhwIjoyMDcwMTQyMDU2fQ.wwrrCv8xd3uECT24fBKasPk5MJPz3hlS_32jzJebbhs';
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

// Frontend and Backend URLs (global scope for use in multiple endpoints)
const frontendUrl = process.env.FRONTEND_URL || 
    (process.env.NODE_ENV === 'production' 
        ? 'https://snappycards.netlify.app' 
        : 'http://localhost:3000');
const backendUrl = process.env.BACKEND_URL || 
    (process.env.NODE_ENV === 'production' 
        ? 'https://snappycards-api.onrender.com' 
        : 'http://localhost:8080');

// Debug URLs


// Verify Resend API key
if (!process.env.RESEND_API_KEY) {
    console.error('❌ RESEND_API_KEY environment variable is required');
    console.error('   Please set your Resend API key:');
    console.error('   export RESEND_API_KEY="your_api_key_here"');
    process.exit(1);
} else {
    console.log('✅ Resend API initialized - Version 2025.01.25');
}

// Verify Supabase Service Key
if (!process.env.SUPABASE_SERVICE_KEY) {
    console.error('❌ SUPABASE_SERVICE_KEY environment variable is required');
    console.error('   Please set your Supabase Service Role key in .env file');
    process.exit(1);
} else {
    console.log('✅ Supabase Admin API initialized');
    console.log(`🔗 Using Supabase project: ${supabaseUrl}`);
}

// Elegant verification email templates (from lib/resend.ts)
function createVerificationEmailTemplate(firstName, verificationUrl, language = 'hu') {
  const templates = {
    hu: {
      subject: '🎯 Snappy Cards - Erősítsd meg az e-mail címed',
      html: `
        <div style="max-width: 600px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; text-align: center; border-radius: 20px 20px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px; font-weight: bold;">
              ✨ Snappy Cards
            </h1>
            <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0; font-size: 16px;">
              Tanulj nyelveket interaktív kártyákkal
            </p>
          </div>
          
          <div style="background: white; padding: 40px 20px; border-radius: 0 0 20px 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
            <h2 style="color: #333; margin: 0 0 20px; font-size: 24px;">
              Szia ${firstName}! 👋
            </h2>
            
            <p style="color: #666; line-height: 1.6; margin: 0 0 30px; font-size: 16px;">
              Köszönjük a regisztrációt! Hogy elkezdhess tanulni, kérjük erősítsd meg az e-mail címed.
            </p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${verificationUrl}" 
                 style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                        color: white; 
                        text-decoration: none; 
                        padding: 15px 30px; 
                        border-radius: 50px; 
                        font-weight: bold; 
                        font-size: 16px;
                        display: inline-block;
                        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);">
                🚀 E-mail cím megerősítése
              </a>
            </div>
            
            <p style="color: #999; font-size: 14px; margin: 30px 0 0; text-align: center;">
              Ha nem te regisztráltál, figyelmen kívül hagyhatod ezt az e-mailt.
            </p>
          </div>
        </div>
      `,
    },
    en: {
      subject: '🎯 Snappy Cards - Verify your email address',
      html: `
        <div style="max-width: 600px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; text-align: center; border-radius: 20px 20px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px; font-weight: bold;">
              ✨ Snappy Cards
            </h1>
            <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0; font-size: 16px;">
              Learn languages with interactive flashcards
            </p>
          </div>
          
          <div style="background: white; padding: 40px 20px; border-radius: 0 0 20px 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
            <h2 style="color: #333; margin: 0 0 20px; font-size: 24px;">
              Hi ${firstName}! 👋
            </h2>
            
            <p style="color: #666; line-height: 1.6; margin: 0 0 30px; font-size: 16px;">
              Thanks for signing up! To start learning, please verify your email address.
            </p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${verificationUrl}" 
                 style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                        color: white; 
                        text-decoration: none; 
                        padding: 15px 30px; 
                        border-radius: 50px; 
                        font-weight: bold; 
                        font-size: 16px;
                        display: inline-block;
                        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);">
                🚀 Verify Email Address
              </a>
            </div>
            
            <p style="color: #999; font-size: 14px; margin: 30px 0 0; text-align: center;">
              If you didn't sign up, you can safely ignore this email.
            </p>
          </div>
        </div>
      `,
    }
  };

  return templates[language] || templates['hu'];
}

// Health check endpoint
app.get('/', (req, res) => {
    res.json({
        status: 'OK',
        message: 'SnappyCards Email API is running',
        timestamp: new Date().toISOString(),
        email_provider: 'Resend API'
    });
});

// Register user endpoint - with Resend verification email
app.post('/register', async (req, res) => {
    try {
        const { firstName, email, password, userRole = 'student', schoolName, language = 'hu', supabaseUserId, createSupabaseUser = false } = req.body;

        // Input validation
        if (!firstName || !email || !password) {
            return res.status(400).json({
                success: false,
                error: 'First name, email and password are required'
            });
        }

        // Email format validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid email format'
            });
        }

        // Password validation
        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                error: 'Password must be at least 6 characters long'
            });
        }

        // User role validation
        const validRoles = ['student', 'teacher', 'school_admin', 'admin'];
        if (!validRoles.includes(userRole)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid user role. Must be student, teacher, school_admin, or admin'
            });
        }

        // School admin specific validation
        if (userRole === 'school_admin' && !schoolName) {
            return res.status(400).json({
                success: false,
                error: 'School name is required for school admin accounts'
            });
        }

        // URLs are now defined globally at the top of the file

        // Step 1: Create Supabase user if requested (without automatic email)
        let actualSupabaseUserId = supabaseUserId;
        
        if (createSupabaseUser) {
            try {
                const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
                    email: email,
                    password: password,
                    user_metadata: {
                        first_name: firstName,
                        user_role: userRole,
                        language: language,
                        school_name: schoolName // Include school name for school_admin
                    },
                    email_confirm: false // Important: Don't send Supabase email
                });
                
                if (createError) {
                    console.error('❌ Supabase user creation error:', createError);
                    throw createError;
                }
                
                actualSupabaseUserId = newUser.user.id;
        
                
            } catch (supabaseError) {
                console.error('❌ Failed to create Supabase user:', supabaseError);
                return res.status(500).json({
                    success: false,
                    error: 'Failed to create user account',
                    details: supabaseError.message
                });
            }
        }

        // Step 2: Create verification URL and email template
        const verificationUrl = `${backendUrl}/verify?email=${encodeURIComponent(email)}&supabase_user_id=${actualSupabaseUserId || 'pending'}`;
        const template = createVerificationEmailTemplate(firstName, verificationUrl, language);



        // Send email via Resend
        const { data, error } = await resend.emails.send({
            from: 'Snappy Cards <noreply@snappycards.io>',
            to: [email],
            subject: template.subject,
            html: template.html,
        });

        if (error) {
            console.error('❌ Resend email error:', error);
            throw new Error('Failed to send verification email');
        }



        res.json({
            success: true,
            message: actualSupabaseUserId 
                ? 'User created in Supabase. Beautiful verification email sent via Resend.'
                : 'Registration initiated. Please check your email for verification.',
            emailId: data.id,
            firstName: firstName,
            email: email,
            userRole: userRole,
            verificationUrl: verificationUrl,
            provider: 'resend',
            supabaseUserId: actualSupabaseUserId,
            hybrid: !!actualSupabaseUserId,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('❌ Registration failed:', error);
        
        res.status(500).json({
            success: false,
            error: error.message || 'Registration failed',
            provider: 'resend',
            timestamp: new Date().toISOString()
        });
    }
});

// Send confirmation email endpoint (for waitlist)
app.post('/send-confirmation', async (req, res) => {
    try {
        const { email, confirmationToken } = req.body;

        // Input validation
        if (!email || !confirmationToken) {
            return res.status(400).json({
                success: false,
                error: 'Email and confirmation token are required'
            });
        }

        // Email format validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid email format'
            });
        }

        // Generate confirmation URL
        const confirmationUrl = `https://snappycards.netlify.app/confirm?token=${confirmationToken}`;

        // Get email template for waitlist
        const template = createVerificationEmailTemplate('Kedves felhasználó', confirmationUrl, 'hu');



        // Send email via Resend
        const { data, error } = await resend.emails.send({
            from: 'Snappy Cards <noreply@snappycards.io>',
            to: [email],
            subject: '🎯 Snappy Cards - Erősítsd meg waitlist helyedet',
            html: template.html,
        });

        if (error) {
            console.error('❌ Resend email error:', error);
            throw new Error('Failed to send confirmation email');
        }
        


        res.json({
            success: true,
            message: 'Confirmation email sent successfully',
            emailId: data.id,
            email: email,
            confirmationUrl: confirmationUrl,
            provider: 'resend',
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('❌ Email sending failed:', error);
        
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to send confirmation email',
            provider: 'resend',
            timestamp: new Date().toISOString()
        });
    }
});

// Email verification endpoint - handles automatic login
app.get('/verify', async (req, res) => {
    try {
        const { email, supabase_user_id } = req.query;

        if (!email) {
            return res.status(400).send(`
                <!DOCTYPE html>
                <html><head><title>Verification Error</title></head>
                <body style="font-family: system-ui; text-align: center; padding: 50px;">
                    <h1 style="color: #dc2626;">❌ Verification Error</h1>
                    <p>Email address is required for verification.</p>
                    <a href="${frontendUrl}/login.html" style="color: #667eea;">Go to Login</a>
                </body></html>
            `);
        }



        // Confirm the user in Supabase using Admin API
        if (supabase_user_id && supabase_user_id !== 'pending') {
            try {
                const { data: userData, error: confirmError } = await supabaseAdmin.auth.admin.updateUserById(
                    supabase_user_id,
                    { 
                        email_confirm: true,
                        email_confirmed_at: new Date().toISOString()
                    }
                );

                if (confirmError) {
                    console.error('⚠️ Supabase confirmation error:', confirmError);
                } else {
    
                    
                    // Create user profile and school if needed
                    await createUserProfileAndSchool(userData.user);
                }
            } catch (adminError) {
                console.error('⚠️ Admin API error:', adminError);
            }
        }

        // Success page with automatic redirect
        res.send(`
            <!DOCTYPE html>
            <html lang="hu">
            <head>
                <meta charset="UTF-8">
                <title>Email Megerősítve - SnappyCards</title>
                <style>
                    body { 
                        font-family: 'Inter', system-ui; 
                        background: linear-gradient(135deg, #f1f5f9 0%, #c7d2fe 100%);
                        text-align: center; 
                        padding: 50px 20px; 
                        min-height: 100vh;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                    }
                    .container {
                        background: rgba(255, 255, 255, 0.9);
                        backdrop-filter: blur(12px);
                        border-radius: 24px;
                        padding: 40px;
                        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                        max-width: 500px;
                    }
                    h1 { 
                        color: #16a34a; 
                        font-size: 2.5rem; 
                        margin-bottom: 1rem;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        -webkit-background-clip: text;
                        -webkit-text-fill-color: transparent;
                    }
                    p { 
                        color: #64748b; 
                        font-size: 1.1rem; 
                        margin-bottom: 2rem;
                        line-height: 1.6;
                    }
                    .btn {
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        padding: 16px 32px;
                        border-radius: 16px;
                        text-decoration: none;
                        font-weight: 600;
                        font-size: 16px;
                        display: inline-block;
                        box-shadow: 0 4px 16px rgba(102, 126, 234, 0.4);
                        transition: all 0.3s ease;
                        margin: 8px;
                    }
                    .btn:hover {
                        box-shadow: 0 8px 32px rgba(102, 126, 234, 0.6);
                        transform: translateY(-2px);
                    }
                    .redirect-info {
                        font-size: 14px;
                        color: #94a3b8;
                        margin-top: 20px;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>✅ Email Megerősítve!</h1>
                    <p>
                        Sikeresen megerősítettük az email címedet: <strong>${email}</strong><br>
                        Most már bejelentkezhetsz a Snappy Cards fiókodba!
                    </p>
                    <a href="${frontendUrl}/login.html?verified=true&email=${encodeURIComponent(email)}" class="btn">
                        🚀 Bejelentkezés
                    </a>
                    <div class="redirect-info">
                        Automatikus átirányítás 5 másodperc múlva...
                    </div>
                </div>
                
                <script>
                    setTimeout(() => {
                        window.location.href = '${frontendUrl}/login.html?verified=true&email=${encodeURIComponent(email)}';
                    }, 5000);
                </script>
            </body>
            </html>
        `);

    } catch (error) {
        console.error('❌ Verification error:', error);
        res.status(500).send(`
            <!DOCTYPE html>
            <html><head><title>Verification Error</title></head>
            <body style="font-family: system-ui; text-align: center; padding: 50px;">
                <h1 style="color: #dc2626;">❌ Verification Error</h1>
                <p>Something went wrong during verification.</p>
                <a href="${frontendUrl}/login.html" style="color: #667eea;">Go to Login</a>
            </body></html>
        `);
    }
});

// Helper function to create user profile and school
async function createUserProfileAndSchool(user) {
    try {
        const { id: userId, user_metadata } = user;
        const { first_name, user_role, school_name } = user_metadata || {};
        
    
        
        let schoolId = null;
        
        // If school_admin, create school first
        if (user_role === 'school_admin' && school_name) {

            
            const { data: schoolData, error: schoolError } = await supabaseAdmin
                .from('schools')
                .insert({
                    name: school_name,
                    description: `School managed by ${first_name}`,
                    contact_email: user.email,
                    is_active: true
                })
                .select()
                .single();
                
            if (schoolError) {
                console.error('❌ Failed to create school:', schoolError);
                throw schoolError;
            }
            
            schoolId = schoolData.id;

        }
        
        // Create user profile
        const { data: profileData, error: profileError } = await supabaseAdmin
            .from('user_profiles')
            .insert({
                id: userId,
                first_name: first_name || '',
                last_name: '', // Can be added later
                user_role: user_role || 'student',
                school_id: schoolId
            })
            .select()
            .single();
            
        if (profileError) {
            console.error('❌ Failed to create user profile:', profileError);
            throw profileError;
        }
        

        
        return { profile: profileData, schoolId };
        
    } catch (error) {
        console.error('❌ Error in createUserProfileAndSchool:', error);
        throw error;
    }
}

// ====================================
// ADMIN ENDPOINTS (School Admin Only)
// ====================================

// Middleware to verify admin permissions
async function verifyAdminAccess(req, res, next) {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                error: 'Missing or invalid authorization header',
                details: 'Provide Bearer token in Authorization header'
            });
        }

        const token = authHeader.split(' ')[1];
        
        // Verify the JWT token with Supabase
        const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);
        
        if (authError || !user) {
            return res.status(401).json({
                error: 'Invalid or expired token',
                details: authError?.message || 'Token verification failed'
            });
        }

        // Check if user has school_admin role
        const userRole = user.user_metadata?.user_role;
        if (userRole !== 'school_admin') {
            return res.status(403).json({
                error: 'Insufficient permissions',
                details: 'Only school administrators can perform this action',
                userRole
            });
        }

        // Get user's school info
        const { data: adminProfile, error: profileError } = await supabaseAdmin
            .from('user_profiles')
            .select('school_id')
            .eq('id', user.id)
            .single();

        if (profileError || !adminProfile?.school_id) {
            return res.status(403).json({
                error: 'Admin profile not found or no school assigned',
                details: profileError?.message || 'Invalid admin profile'
            });
        }

        // Add user and school info to request
        req.adminUser = user;
        req.adminSchoolId = adminProfile.school_id;
        next();
    } catch (error) {
        console.error('Admin verification error:', error);
        return res.status(500).json({
            error: 'Internal server error during authentication',
            details: error.message
        });
    }
}

// Admin endpoint: Update teacher profile
app.post('/admin/update-teacher', verifyAdminAccess, async (req, res) => {
    try {
        const { teacherId, firstName, lastName, note } = req.body;

        if (!teacherId || !firstName || !lastName) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['teacherId', 'firstName', 'lastName'],
                received: { teacherId, firstName, lastName, note }
            });
        }

        // Verify teacher belongs to admin's school
        const { data: teacher, error: teacherError } = await supabaseAdmin
            .from('user_profiles')
            .select('id, school_id, user_role, first_name, last_name')
            .eq('id', teacherId)
            .eq('school_id', req.adminSchoolId)
            .eq('user_role', 'teacher')
            .single();

        if (teacherError || !teacher) {
            return res.status(404).json({
                error: 'Teacher not found or access denied',
                details: teacherError?.message || 'Teacher not in your school',
                adminSchoolId: req.adminSchoolId,
                teacherId
            });
        }

        // Update teacher profile using service role (bypasses RLS)
        const { data: updatedProfile, error: updateError } = await supabaseAdmin
            .from('user_profiles')
            .update({
                first_name: firstName,
                last_name: lastName,
                note: note || null,
                updated_at: new Date().toISOString()
            })
            .eq('id', teacherId)
            .select()
            .single();

        if (updateError) {
            console.error('Teacher update error:', updateError);
            return res.status(500).json({
                error: 'Failed to update teacher profile',
                details: updateError.message
            });
        }



        res.json({
            success: true,
            message: 'Teacher profile updated successfully',
            data: {
                teacher: updatedProfile,
                changes: {
                    firstName: { from: teacher.first_name, to: firstName },
                    lastName: { from: teacher.last_name, to: lastName },
                    note: { to: note }
                }
            }
        });

    } catch (error) {
        console.error('Error in /admin/update-teacher:', error);
        res.status(500).json({
            error: 'Internal server error',
            details: error.message
        });
    }
});

// Admin endpoint: Update teacher email (via Supabase Auth Admin API)
app.post('/admin/update-teacher-email', verifyAdminAccess, async (req, res) => {
    try {
        const { teacherId, newEmail } = req.body;

        if (!teacherId || !newEmail) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['teacherId', 'newEmail']
            });
        }

        // Email validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(newEmail)) {
            return res.status(400).json({
                error: 'Invalid email format',
                received: newEmail
            });
        }

        // Verify teacher belongs to admin's school
        const { data: teacher, error: teacherError } = await supabaseAdmin
            .from('user_profiles')
            .select('id, school_id, user_role, is_mock')
            .eq('id', teacherId)
            .eq('school_id', req.adminSchoolId)
            .eq('user_role', 'teacher')
            .single();

        if (teacherError || !teacher) {
            return res.status(404).json({
                error: 'Teacher not found or access denied',
                details: teacherError?.message || 'Teacher not in your school'
            });
        }

        // Update email in user_profiles table for all users (mock and real)

        const { data: profileUpdate, error: profileUpdateError } = await supabaseAdmin
            .from('user_profiles')
            .update({ email: newEmail })
            .eq('id', teacherId)
            .select();



        if (profileUpdateError) {
            console.error('Profile email update error:', profileUpdateError);
            return res.status(500).json({
                error: 'Failed to update teacher email in profile',
                details: profileUpdateError.message
            });
        }

        // Handle mock users differently (simulate auth email update)
        if (teacher.is_mock) {

            
            // For mock users, just return success without calling Auth API
            return res.json({
                success: true,
                message: 'Teacher email updated successfully (demo mode)',
                data: {
                    teacherId,
                    newEmail,
                    isMock: true,
                    updatedAt: new Date().toISOString()
                }
            });
        }

        // Update user email using Supabase Auth Admin API (for real users)
        const { data: authUser, error: emailUpdateError } = await supabaseAdmin.auth.admin.updateUserById(
            teacherId,
            { email: newEmail }
        );

        if (emailUpdateError) {
            console.error('Email update error:', emailUpdateError);
            return res.status(500).json({
                error: 'Failed to update teacher email',
                details: emailUpdateError.message
            });
        }



        res.json({
            success: true,
            message: 'Teacher email updated successfully',
            data: {
                teacherId,
                newEmail,
                updatedAt: new Date().toISOString()
            }
        });

    } catch (error) {
        console.error('Error in /admin/update-teacher-email:', error);
        res.status(500).json({
            error: 'Internal server error',
            details: error.message
        });
    }
});

// Admin endpoint: Update teacher password
app.post('/admin/update-teacher-password', verifyAdminAccess, async (req, res) => {
    try {
        const { teacherId, newPassword } = req.body;

        if (!teacherId || !newPassword) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['teacherId', 'newPassword']
            });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({
                error: 'Password too short',
                details: 'Password must be at least 6 characters long'
            });
        }

        // Verify teacher belongs to admin's school
        const { data: teacher, error: teacherError } = await supabaseAdmin
            .from('user_profiles')
            .select('id, school_id, user_role, is_mock')
            .eq('id', teacherId)
            .eq('school_id', req.adminSchoolId)
            .eq('user_role', 'teacher')
            .single();

        if (teacherError || !teacher) {
            return res.status(404).json({
                error: 'Teacher not found or access denied',
                details: teacherError?.message || 'Teacher not in your school'
            });
        }

        // Handle mock users differently (store password in database)
        if (teacher.is_mock) {

            
            // For mock users, store password in database instead of Auth
            const { data: passwordUpdate, error: passwordError } = await supabaseAdmin
                .from('user_profiles')
                .update({ stored_password: newPassword })
                .eq('id', teacherId)
                .select();
            
            if (passwordError) {
                console.error('Error storing mock user password:', passwordError);
                return res.status(500).json({
                    error: 'Failed to store password',
                    details: passwordError.message
                });
            }
            
            return res.json({
                success: true,
                message: 'Teacher password updated successfully (demo mode)',
                data: {
                    teacherId,
                    isMock: true,
                    updatedAt: new Date().toISOString(),
                    passwordStored: true
                }
            });
        }

        // Update user password using Supabase Auth Admin API (for real users)
        const { data: authUser, error: passwordUpdateError } = await supabaseAdmin.auth.admin.updateUserById(
            teacherId,
            { password: newPassword }
        );

        if (passwordUpdateError) {
            console.error('Password update error:', passwordUpdateError);
            return res.status(500).json({
                error: 'Failed to update teacher password',
                details: passwordUpdateError.message
            });
        }



        res.json({
            success: true,
            message: 'Teacher password updated successfully',
            data: {
                teacherId,
                updatedAt: new Date().toISOString()
            }
        });

    } catch (error) {
        console.error('Error in /admin/update-teacher-password:', error);
        res.status(500).json({
            error: 'Internal server error',
            details: error.message
        });
    }
});

// Include public routes
const publicRoutes = require('./src/routes/public');
app.use('/', publicRoutes);

// CORS preflight for endpoints
app.options('/register', cors());
app.options('/send-confirmation', cors());
app.options('/verify', cors());
app.options('/custom-login', cors());
app.options('/admin/update-teacher', cors());
app.options('/admin/update-teacher-email', cors());
app.options('/admin/update-teacher-password', cors());

// Start server
app.listen(PORT, () => {
    console.log(`🚀 SnappyCards API Server running on port ${PORT}`);
    console.log(`📧 Email Provider: Resend API`);
    console.log(`📬 From: noreply@snappycards.io`);
    console.log(`🎯 Endpoints: /register, /send-confirmation, /verify, /verify`);
    console.log(`🏫 Admin Endpoints: /admin/update-teacher, /admin/update-teacher-email, /admin/update-teacher-password`);
});

module.exports = app; // Force deployment Mon Aug  4 15:19:08 CEST 2025
