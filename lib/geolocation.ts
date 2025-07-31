// Geolocation utility for language detection
export async function getLocationFromIP(): Promise<{
  country: string;
  region: string;
  city: string;
  language: string;
}> {
  try {
    // Client-side IP detection
    const response = await fetch('https://ipapi.co/json/');
    const data = await response.json();
    
    // Language mapping based on country
    const languageMap: { [key: string]: string } = {
      'HU': 'hu', // Hungary
      'US': 'en', // United States
      'GB': 'en', // United Kingdom
      'DE': 'de', // Germany
      'FR': 'fr', // France
      'ES': 'es', // Spain
      'IT': 'it', // Italy
      'RO': 'ro', // Romania
      'SK': 'sk', // Slovakia
      'AT': 'de', // Austria
      'CH': 'de', // Switzerland
    };

    return {
      country: data.country_code || 'US',
      region: data.region || '',
      city: data.city || '',
      language: languageMap[data.country_code] || 'en'
    };
  } catch (error) {
    console.error('Failed to detect location:', error);
    // Fallback to Hungarian for development
    return {
      country: 'HU',
      region: 'Budapest',
      city: 'Budapest',
      language: 'hu'
    };
  }
}

// Language texts for different locales
export const languageTexts = {
  hu: {
    welcome: "Üdvözöl a Snappy Cards!",
    subtitle: "Tanulj nyelveket interaktív kártyákkal",
    signUp: "Regisztráció",
    signIn: "Bejelentkezés",
    email: "E-mail cím",
    firstName: "Keresztnév",
    password: "Jelszó",
    confirmPassword: "Jelszó megerősítése",
    createAccount: "Fiók létrehozása",
    alreadyHaveAccount: "Már van fiókod?",
    dontHaveAccount: "Nincs még fiókod?",
    forgotPassword: "Elfelejtett jelszó?",
  },
  en: {
    welcome: "Welcome to Snappy Cards!",
    subtitle: "Learn languages with interactive flashcards",
    signUp: "Sign Up",
    signIn: "Sign In",
    email: "Email address",
    firstName: "First name",
    password: "Password",
    confirmPassword: "Confirm password",
    createAccount: "Create account",
    alreadyHaveAccount: "Already have an account?",
    dontHaveAccount: "Don't have an account?",
    forgotPassword: "Forgot password?",
  }
};