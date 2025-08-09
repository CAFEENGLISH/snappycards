const express = require('express');
const router = express.Router();

const { supabaseAdmin } = require('../config/database');
const { resend } = require('../config/email');
const { frontendUrl, backendUrl } = require('../config/environment');
const { createVerificationEmailTemplate } = require('../utils/emailTemplates');
const { createUserProfileAndSchool } = require('../utils/userHelpers');

// Health check endpoint
router.get('/', (req, res) => {
    res.json({
        status: 'OK',
        message: 'SnappyCards Email API is running',
        timestamp: new Date().toISOString(),
        email_provider: 'Resend API'
    });
});

// Custom login endpoint - bypasses broken Supabase Auth
router.post('/custom-login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                error: 'Email and password are required'
            });
        }

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid email format'
            });
        }

        // Check user in user_profiles table
        const { data: user, error: userError } = await supabaseAdmin
            .from('user_profiles')
            .select('id, email, first_name, user_role, stored_password')
            .eq('email', email.toLowerCase())
            .single();

        if (userError || !user) {
            return res.status(401).json({
                success: false,
                error: 'Invalid email or password'
            });
        }

        // Check password (stored_password field)
        if (user.stored_password !== password) {
            return res.status(401).json({
                success: false,
                error: 'Invalid email or password'
            });
        }

        // Generate a simple session token (you can implement JWT if needed)
        const sessionToken = Buffer.from(`${user.id}:${user.email}:${Date.now()}`).toString('base64');
        
        // Return successful login response
        res.json({
            success: true,
            message: 'Login successful',
            user: {
                id: user.id,
                email: user.email,
                firstName: user.first_name,
                userRole: user.user_role
            },
            sessionToken: sessionToken,
            // Include auth data for compatibility
            auth: {
                user: {
                    id: user.id,
                    email: user.email,
                    user_metadata: {
                        first_name: user.first_name,
                        user_role: user.user_role
                    }
                },
                session: {
                    access_token: sessionToken,
                    user: {
                        id: user.id,
                        email: user.email
                    }
                }
            }
        });

    } catch (error) {
        console.error('Custom login error:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error during login',
            details: error.message
        });
    }
});

// User registration endpoint
router.post('/register', async (req, res) => {
    try {
        const { email, firstName, language = 'hu', userRole = 'student', schoolName } = req.body;

        if (!email || !firstName) {
            return res.status(400).json({
                success: false,
                error: 'Email and first name are required'
            });
        }

        // Email validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid email format'
            });
        }

        let actualSupabaseUserId = null;

        // Step 1: Create user in Supabase Auth (only if not waitlist)
        if (userRole !== 'waitlist') {
            try {
                const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
                    email,
                    email_confirm: false,
                    user_metadata: {
                        first_name: firstName,
                        user_role: userRole,
                        school_name: schoolName || null
                    }
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
                : 'Added to waitlist. Beautiful confirmation email sent via Resend.',
            emailId: data.id,
            supabaseUserId: actualSupabaseUserId
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            error: 'Registration failed',
            details: error.message
        });
    }
});

// Waitlist confirmation endpoint
router.post('/send-confirmation', async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                error: 'Email is required'
            });
        }

        // Generate simple confirmation token
        const confirmationToken = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
        const confirmationUrl = `https://snappycards.netlify.app/confirm?token=${confirmationToken}`;

        // Get email template for waitlist
        const template = createVerificationEmailTemplate('Kedves felhasználó', confirmationUrl, 'hu');

        // Send email via Resend
        const { data, error } = await resend.emails.send({
            from: 'Snappy Cards <noreply@snappycards.io>',
            to: [email],
            subject: template.subject,
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
            confirmationToken
        });

    } catch (error) {
        console.error('Send confirmation error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to send confirmation email',
            details: error.message
        });
    }
});

// Email verification endpoint
router.get('/verify', async (req, res) => {
    try {
        const { email, supabase_user_id } = req.query;

        if (!email) {
            return res.status(400).send(`
                <html><body>
                    <h1>❌ Missing Email</h1>
                    <p>Email parameter is required for verification.</p>
                    <a href="${frontendUrl}/login.html" style="color: #667eea;">Go to Login</a>
                </body></html>
            `);
        }

        // Confirm the user in Supabase using Admin API
        if (supabase_user_id && supabase_user_id !== 'pending') {
            try {
                const { data: userData, error: confirmError } = await supabaseAdmin.auth.admin.updateUserById(
                    supabase_user_id,
                    { email_confirm: true }
                );

                if (confirmError) {
                    console.error('⚠️ Supabase confirmation error:', confirmError);
                } else {
                    // Create user profile and school if needed
                    await createUserProfileAndSchool(userData.user);
                }
            } catch (adminError) {
                console.error('⚠️ Admin confirmation error:', adminError);
            }
        }

        // Return success page
        res.send(`
            <html>
            <head>
                <title>✅ Email Verified - Snappy Cards</title>
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                    body { 
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                        max-width: 600px; 
                        margin: 40px auto; 
                        padding: 20px; 
                        text-align: center;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        min-height: 100vh;
                        margin: 0;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                    }
                    .container {
                        background: white;
                        padding: 40px;
                        border-radius: 20px;
                        box-shadow: 0 10px 30px rgba(0,0,0,0.2);
                    }
                    h1 { color: #333; margin-bottom: 20px; }
                    p { color: #666; line-height: 1.6; margin-bottom: 30px; }
                    a { 
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                        color: white; 
                        text-decoration: none; 
                        padding: 15px 30px; 
                        border-radius: 50px; 
                        font-weight: bold;
                        display: inline-block;
                        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
                    }
                    a:hover { transform: translateY(-2px); }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>🎉 Email Successfully Verified!</h1>
                    <p>Your email <strong>${email}</strong> has been verified successfully!</p>
                    <p>You can now log in to your Snappy Cards account and start learning.</p>
                    <a href="${frontendUrl}/login.html">🚀 Go to Login</a>
                </div>
            </body>
            </html>
        `);

    } catch (error) {
        console.error('❌ Verification error:', error);
        res.status(500).send(`
            <html><body>
                <h1>❌ Verification Failed</h1>
                <p>Sorry, there was an error verifying your email.</p>
                <p>Error: ${error.message}</p>
                <a href="${frontendUrl}/login.html" style="color: #667eea;">Go to Login</a>
            </body></html>
        `);
    }
});

module.exports = router;