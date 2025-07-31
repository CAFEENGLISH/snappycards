import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export interface EmailVerificationData {
  email: string;
  firstName: string;
  verificationUrl: string;
  language: 'hu' | 'en';
}

export async function sendVerificationEmail(data: EmailVerificationData) {
  const { email, firstName, verificationUrl, language } = data;

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

  const template = templates[language];

  try {
    const { data, error } = await resend.emails.send({
      from: 'Snappy Cards <noreply@snappycards.io>',
      to: [email],
      subject: template.subject,
      html: template.html,
    });

    if (error) {
      console.error('Failed to send email:', error);
      throw new Error('Failed to send verification email');
    }

    return data;
  } catch (error) {
    console.error('Email sending error:', error);
    throw error;
  }
}