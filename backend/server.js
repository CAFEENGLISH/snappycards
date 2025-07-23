const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Zoho SMTP Configuration (same as Python script that worked)
const smtpConfig = {
    host: 'smtp.zoho.com',
    port: 587,
    secure: false, // Use TLS
    auth: {
        user: 'info@snappycards.io',
        pass: 'QrfRsj9yPzaB' // The App Password that worked
    }
};

// Create nodemailer transporter
const transporter = nodemailer.createTransport(smtpConfig);

// Verify SMTP connection
transporter.verify((error, success) => {
    if (error) {
        console.error('SMTP Connection Failed:', error);
    } else {
        console.log('✅ SMTP Server Ready for messages');
    }
});

// Email template function
function createEmailTemplate(email, confirmationUrl) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>SnappyCards Waitlist Megerősítés</title>
        <style>
            body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; padding: 0; background: #f8fafc; }
            .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 8px 32px rgba(0,0,0,0.1); }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center; }
            .header h1 { color: white; font-size: 32px; margin: 0; font-weight: 800; letter-spacing: -0.02em; }
            .header p { color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 16px; font-weight: 500; }
            .content { padding: 40px 30px; }
            .content h2 { color: #1a202c; font-size: 24px; margin-bottom: 20px; font-weight: 700; }
            .content p { color: #4a5568; line-height: 1.6; margin-bottom: 20px; font-size: 16px; }
            .cta-button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 18px 36px; text-decoration: none; border-radius: 50px; font-weight: 600; margin: 20px 0; font-size: 16px; }
            .footer { background: #f8fafc; padding: 30px; text-align: center; color: #718096; font-size: 14px; border-top: 1px solid #e2e8f0; }
            .token { background: #f1f5f9; padding: 15px; border-radius: 8px; font-family: monospace; font-size: 13px; word-break: break-all; margin: 20px 0; }
            .highlight { color: #667eea; font-weight: 600; }
        </style>
    </head>
    <body>
        <div style="padding: 20px;">
            <div class="container">
                <div class="header">
                    <h1>🧠 SnappyCards</h1>
                    <p>AI-Powered Learning Revolution</p>
                </div>
                <div class="content">
                    <h2>Üdvözölünk a tanulás jövőjében! 🚀</h2>
                    <p>Köszönjük, hogy csatlakoztál a <span class="highlight">SnappyCards waitlist</span>-hez! Hamarosan megtapasztalhatod a világ első FlashCard rendszerét, amit az agyad is imádni fog.</p>
                    
                    <p>A regisztráció befejezéséhez és a helyedet biztosításához, kérjük erősítsd meg az email címedet:</p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="${confirmationUrl}" class="cta-button">✨ Email cím megerősítése</a>
                    </div>
                    
                    <p><strong>Nem működik a gomb?</strong> Másold be ezt a linket:</p>
                    <div class="token">${confirmationUrl}</div>
                    
                    <p><strong>🎯 Mi történik ezután?</strong></p>
                    <ul>
                        <li><strong>Exkluzív korai hozzáférés</strong> az indulásnál</li>
                        <li><strong>Kulisszatitkok</strong> az AI fejlesztésről</li>
                        <li><strong>Speciális indulási árak</strong> csak waitlist tagoknak</li>
                        <li><strong>Első próbálók</strong> lesztek a forradalmi funkciókban</li>
                    </ul>
                    
                    <p>⏰ <em>Ez a megerősítő link 24 órán belül lejár a biztonság érdekében.</em></p>
                </div>
                <div class="footer">
                    <p><strong>Kérdések?</strong> Válaszolj erre az emailre - minden üzenetet elolvasunk! 💬</p>
                    <p>Ha nem te iratkoztál fel, biztonságosan figyelmen kívül hagyhatod ezt az emailt.</p>
                    <hr style="margin: 20px 0; border: none; border-top: 1px solid #ddd;">
                    <p>&copy; 2025 SnappyCards. 🧠-tel és ⚡-val készítve a tanulás jövőjéért.</p>
                    <p><a href="mailto:info@snappycards.io" style="color: #667eea;">info@snappycards.io</a></p>
                </div>
            </div>
        </div>
    </body>
    </html>
    `;
}

// Health check endpoint
app.get('/', (req, res) => {
    res.json({
        status: 'OK',
        message: 'SnappyCards Email API is running',
        timestamp: new Date().toISOString(),
        smtp_status: 'Connected to smtp.zoho.com'
    });
});

// Send confirmation email endpoint
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

        // Email options
        const mailOptions = {
            from: '"SnappyCards Team" <info@snappycards.io>',
            to: email,
            subject: '🧠 Üdvözölünk a SnappyCards-nál - Erősítsd meg a waitlist helyedet!',
            html: createEmailTemplate(email, confirmationUrl),
            text: `
Üdvözölünk a SnappyCards waitlist-ben!

Kérjük, erősítsd meg az email címedet a következő linkre kattintva:
${confirmationUrl}

Üdvözlettel,
SnappyCards Team
info@snappycards.io
            `
        };

        console.log(`📧 Sending email to: ${email}`);
        console.log(`🔗 Confirmation URL: ${confirmationUrl}`);

        // Send email
        const info = await transporter.sendMail(mailOptions);
        
        console.log('✅ Email sent successfully:', info.messageId);

        res.json({
            success: true,
            message: 'Confirmation email sent successfully',
            messageId: info.messageId,
            from: 'info@snappycards.io',
            to: email,
            confirmationUrl: confirmationUrl,
            provider: 'zoho_smtp',
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('❌ Email sending failed:', error);
        
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to send confirmation email',
            provider: 'zoho_smtp',
            timestamp: new Date().toISOString()
        });
    }
});

// CORS preflight for send-confirmation
app.options('/send-confirmation', cors());

// Start server
app.listen(PORT, () => {
    console.log(`🚀 SnappyCards API Server running on port ${PORT}`);
    console.log(`📧 SMTP: ${smtpConfig.host}:${smtpConfig.port}`);
    console.log(`📬 From: ${smtpConfig.auth.user}`);
});

module.exports = app; 