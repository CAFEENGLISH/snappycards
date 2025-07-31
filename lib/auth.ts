import { supabase } from './supabase';
import { sendVerificationEmail } from './resend';
import { getLocationFromIP } from './geolocation';

export interface SignUpData {
  email: string;
  password: string;
  firstName: string;
  language?: string;
  country?: string;
}

export interface LoginData {
  email: string;
  password: string;
}

export async function signUp(data: SignUpData) {
  try {
    // Get location and language if not provided
    let { language, country } = data;
    if (!language || !country) {
      const location = await getLocationFromIP();
      language = language || location.language;
      country = country || location.country;
    }

    // Sign up with Supabase Auth
    const { data: authData, error: signUpError } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        data: {
          first_name: data.firstName,
          language: language,
          country: country,
        },
      },
    });

    if (signUpError) {
      throw signUpError;
    }

    if (!authData.user) {
      throw new Error('Nem sikerült létrehozni a felhasználót');
    }

    // Send verification email via Resend
    if (authData.user && !authData.user.email_confirmed_at) {
      // Get the verification URL from Supabase
      const verificationUrl = `${window.location.origin}/auth/verify?token=${authData.user.id}&email=${encodeURIComponent(data.email)}`;
      
      await sendVerificationEmail({
        email: data.email,
        firstName: data.firstName,
        verificationUrl,
        language: language as 'hu' | 'en',
      });
    }

    return {
      user: authData.user,
      session: authData.session,
      needsVerification: !authData.user.email_confirmed_at,
    };
  } catch (error) {
    console.error('Sign up error:', error);
    throw error;
  }
}

export async function signIn(data: LoginData) {
  try {
    const { data: authData, error } = await supabase.auth.signInWithPassword({
      email: data.email,
      password: data.password,
    });

    if (error) {
      throw error;
    }

    return {
      user: authData.user,
      session: authData.session,
    };
  } catch (error) {
    console.error('Sign in error:', error);
    throw error;
  }
}

export async function signOut() {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) {
      throw error;
    }
  } catch (error) {
    console.error('Sign out error:', error);
    throw error;
  }
}

export async function getCurrentUser() {
  try {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) {
      throw error;
    }
    return user;
  } catch (error) {
    console.error('Get current user error:', error);
    return null;
  }
}

export async function verifyEmail(token: string, email: string) {
  try {
    // This would typically use Supabase's built-in verification
    // For now, we'll implement a simple token verification
    const { data, error } = await supabase.auth.verifyOtp({
      token_hash: token,
      type: 'email',
    });

    if (error) {
      throw error;
    }

    return data;
  } catch (error) {
    console.error('Email verification error:', error);
    throw error;
  }
}