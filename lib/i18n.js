/**
 * 🌍 Snappy Cards Internationalization Engine
 * Központi lokalizációs motor - Magyar, Angol, Thai támogatással
 * Automatikus aktiválódás minden oldalon és módosításkor
 */

// 🌐 Támogatott nyelvek
const SUPPORTED_LANGUAGES = {
    'hu': '🇭🇺 Magyar',
    'en': '🇺🇸 English', 
    'th': '🇹🇭 ไทย'
};

// 📚 Központi fordítási adatbázis
const TRANSLATIONS = {
    hu: {
        // Közös navigáció és alapok
        common: {
            snappyCards: "Snappy Cards",
            loading: "Betöltés...",
            save: "Mentés",
            cancel: "Mégse", 
            close: "Bezárás",
            edit: "Szerkesztés",
            delete: "Törlés",
            create: "Létrehozás",
            back: "Vissza",
            next: "Tovább",
            previous: "Előző",
            yes: "Igen",
            no: "Nem",
            ok: "OK",
            error: "Hiba",
            success: "Siker"
        },
        // Főoldal
        home: {
            title: "Snappy Cards - Intelligens Szókártya Tanulás",
            heroTitle: "Tanuld meg a nyelveket gyorsabban és okosabban",
            heroSubtitle: "A Snappy Cards egy modern, mesterséges intelligenciával támogatott platform a hatékony szókártya tanuláshoz.",
            getStarted: "Kezdjük el",
            learnMore: "Tudj meg többet",
            featuresTitle: "Miért válaszd a Snappy Cards-ot?",
            feature1Title: "🚀 Gyors és Hatékony",
            feature1Desc: "Optimalizált algoritmusokkal gyorsabb tanulási eredményeket érhetsz el.",
            feature2Title: "🧠 AI Támogatás", 
            feature2Desc: "Mesterséges intelligencia segít a nehéz szavak felismerésében.",
            feature3Title: "📱 Bármikor, Bárhol",
            feature3Desc: "Tanulj telefonon, tableten vagy számítógépen - szinkronizálva.",
            loginButton: "Bejelentkezés",
            registerButton: "Regisztráció"
        },
        // Bejelentkezés
        auth: {
            loginTitle: "Bejelentkezés",
            registerTitle: "Regisztráció", 
            email: "E-mail cím",
            password: "Jelszó",
            confirmPassword: "Jelszó megerősítése",
            firstName: "Keresztnév",
            lastName: "Vezetéknév",
            loginButton: "Bejelentkezés",
            registerButton: "Regisztráció",
            forgotPassword: "Elfelejtett jelszó?",
            noAccount: "Nincs még fiókod?",
            hasAccount: "Van már fiókod?",
            createAccount: "Fiók létrehozása",
            signIn: "Bejelentkezés",
            emailRequired: "E-mail cím kötelező",
            passwordRequired: "Jelszó kötelező",
            emailInvalid: "Érvénytelen e-mail cím",
            passwordTooShort: "A jelszó túl rövid",
            passwordsDontMatch: "A jelszavak nem egyeznek",
            loginError: "Bejelentkezési hiba",
            registerError: "Regisztrációs hiba",
            loginSuccess: "Sikeres bejelentkezés!",
            registerSuccess: "Sikeres regisztráció!"
        },
        // Dashboard
        dashboard: {
            title: "Dashboard",
            welcome: "Üdvözöllek a Dashboard-on, {name}!",
            subtitle: "Kezeld szókártya szettjeidet és tanulj hatékonyan",
            newSet: "Új szett",
                    settings: "Beállítások",
        tagManager: "TAG Kezelő",
        logout: "Kilépés",
            userMenu: "Felhasználói menü",
            ownSets: "Saját szett",
            joinedSets: "Csatlakozott szett",
            totalCards: "Összes kártya",
            mastered: "Elsajátítva",
            ownSetsTitle: "Saját szettjeim",
            joinedSetsTitle: "👥 Csatlakozott szettjeim",
            newSetButton: "Új szett létrehozása",
            noSets: "Még nincsenek szettjeid. Készíts egyet!",
            cardCount: "kártya",
            masteredCount: "elsajátítva"
        },
        // Tanulás
        study: {
            title: "Tanulás",
            startStudy: "Tanulás kezdése",
            showAnswer: "Válasz mutatása",
            nextCard: "Következő kártya",
            prevCard: "Előző kártya",
            again: "Újra",
            hard: "Nehéz", 
            good: "Jó",
            easy: "Könnyű",
            studyComplete: "Tanulás befejezve!",
            cardsLeft: "Hátralevő kártyák: {count}",
            progress: "Haladás: {current}/{total}"
        },
        // Beállítások
        settings: {
            title: "⚙️ Beállítások",
            interfaceLanguage: "🌍 Snappy Cards felületi nyelve",
            interfaceDescription: "Ez a beállítás határozza meg, hogy milyen nyelven jelenjen meg a Snappy Cards felülete.",
            browserLanguage: "📱 Böngésző nyelve:",
            currentSetting: "⚙️ Jelenlegi beállítás:",
            detectBrowser: "🔍 Böngésző nyelvének automatikus felismerése",
            languageUpdated: "Megjelenési nyelv frissítve: {lang}",
            languageDetected: "Böngésző nyelve felismerve: {lang}",
            languageNotSupported: "A böngésző nyelve ({lang}) nem támogatott. Válassz a listából!"
        },
        // Üzenetek
        messages: {
            success: {
                setCreated: "✅ Szett sikeresen létrehozva!",
                setUpdated: "✅ Szett sikeresen frissítve!",
                setDeleted: "✅ Szett sikeresen törölve!"
            },
            error: {
                nameRequired: "A szett neve kötelező!",
                createError: "Hiba történt a szett létrehozása során!",
                updateError: "Hiba történt a szett mentése során!"
            }
        }
    },
    en: {
        // Common navigation and basics
        common: {
            snappyCards: "Snappy Cards",
            loading: "Loading...",
            save: "Save",
            cancel: "Cancel",
            close: "Close", 
            edit: "Edit",
            delete: "Delete",
            create: "Create",
            back: "Back",
            next: "Next", 
            previous: "Previous",
            yes: "Yes",
            no: "No",
            ok: "OK",
            error: "Error",
            success: "Success"
        },
        // Homepage
        home: {
            title: "SnappyCards - The world's first FlashCard system your brain will actually love",
            heroTitle: "The world's first FlashCard system your brain will actually love",
            heroSubtitle: "Artificial intelligence meets neuroscience. Learn more effectively than ever before.",
            getStarted: "Sign Up",
            learnMore: "Learn More",
            featuresTitle: "Why Choose Snappy Cards?",
            feature1Title: "🚀 Fast and Efficient",
            feature1Desc: "Achieve faster learning results with optimized algorithms.",
            feature2Title: "🧠 AI Support",
            feature2Desc: "Artificial intelligence helps identify difficult words.",
            feature3Title: "📱 Anytime, Anywhere", 
            feature3Desc: "Learn on phone, tablet or computer - synchronized.",
            loginButton: "Login",
            registerButton: "Sign Up"
        },
        // Authentication
        auth: {
            loginTitle: "Sign In",
            registerTitle: "Sign Up",
            email: "Email Address",
            password: "Password",
            confirmPassword: "Confirm Password",
            firstName: "First Name",
            lastName: "Last Name", 
            loginButton: "Sign In",
            registerButton: "Sign Up",
            forgotPassword: "Forgot Password?",
            noAccount: "Don't have an account?",
            hasAccount: "Already have an account?",
            createAccount: "Create Account",
            signIn: "Sign In",
            emailRequired: "Email is required",
            passwordRequired: "Password is required",
            emailInvalid: "Invalid email address",
            passwordTooShort: "Password is too short",
            passwordsDontMatch: "Passwords don't match",
            loginError: "Login error",
            registerError: "Registration error",
            loginSuccess: "Login successful!",
            registerSuccess: "Registration successful!"
        },
        // Dashboard
        dashboard: {
            title: "Dashboard",
            welcome: "Welcome to Dashboard, {name}!",
            subtitle: "Manage your flashcard sets and learn efficiently",
            newSet: "New Set",
            settings: "Settings",
            tagManager: "TAG Manager",
            logout: "Logout",
            userMenu: "User Menu",
            ownSets: "Own Sets",
            joinedSets: "Joined Sets", 
            totalCards: "Total Cards",
            mastered: "Mastered",
            ownSetsTitle: "My Sets",
            joinedSetsTitle: "👥 Joined Sets",
            newSetButton: "Create New Set",
            noSets: "You don't have any sets yet. Create one!",
            cardCount: "cards",
            masteredCount: "mastered"
        },
        // Study
        study: {
            title: "Study",
            startStudy: "Start Study",
            showAnswer: "Show Answer",
            nextCard: "Next Card",
            prevCard: "Previous Card",
            again: "Again",
            hard: "Hard",
            good: "Good",
            easy: "Easy",
            studyComplete: "Study Complete!",
            cardsLeft: "Cards left: {count}",
            progress: "Progress: {current}/{total}"
        },
        // Settings
        settings: {
            title: "⚙️ Settings",
            interfaceLanguage: "🌍 Snappy Cards Interface Language",
            interfaceDescription: "This setting determines the language of the Snappy Cards interface.",
            browserLanguage: "📱 Browser Language:",
            currentSetting: "⚙️ Current Setting:",
            detectBrowser: "🔍 Auto-detect Browser Language",
            languageUpdated: "Interface language updated: {lang}",
            languageDetected: "Browser language detected: {lang}",
            languageNotSupported: "Browser language ({lang}) is not supported. Please choose from the list!"
        },
        // Messages
        messages: {
            success: {
                setCreated: "✅ Set created successfully!",
                setUpdated: "✅ Set updated successfully!",
                setDeleted: "✅ Set deleted successfully!"
            },
            error: {
                nameRequired: "Set name is required!",
                createError: "Error occurred while creating set!",
                updateError: "Error occurred while saving set!"
            }
        }
    },
    th: {
        // ส่วนทั่วไปและพื้นฐาน
        common: {
            snappyCards: "Snappy Cards",
            loading: "กำลังโหลด...",
            save: "บันทึก",
            cancel: "ยกเลิก",
            close: "ปิด",
            edit: "แก้ไข",
            delete: "ลบ",
            create: "สร้าง",
            back: "กลับ",
            next: "ถัดไป",
            previous: "ก่อนหน้า",
            yes: "ใช่",
            no: "ไม่",
            ok: "ตกลง",
            error: "ข้อผิดพลาด",
            success: "สำเร็จ"
        },
        // หน้าแรก
        home: {
            title: "Snappy Cards - ระบบแฟลชการ์ดแรกของโลกที่สมองคุณจะรัก",
            heroTitle: "ระบบแฟลชการ์ดแรกของโลกที่สมองคุณจะรัก",
            heroSubtitle: "ปัญญาประดิษฐ์พบกับประสาทวิทยา เรียนรู้อย่างมีประสิทธิภาพมากขึ้นกว่าที่เคย",
            getStarted: "ลงทะเบียน",
            learnMore: "เรียนรู้เพิ่มเติม",
            featuresTitle: "ทำไมต้องเลือก Snappy Cards?",
            feature1Title: "🚀 รวดเร็วและมีประสิทธิภาพ",
            feature1Desc: "ผลลัพธ์การเรียนรู้ที่เร็วขึ้นด้วยอัลกอริทึมที่ปรับให้เหมาะสม",
            feature2Title: "🧠 การสนับสนุน AI",
            feature2Desc: "ปัญญาประดิษฐ์ช่วยระบุคำที่ยาก",
            feature3Title: "📱 ทุกที่ทุกเวลา",
            feature3Desc: "เรียนรู้บนโทรศัพท์ แท็บเล็ต หรือคอมพิวเตอร์ - ซิงโครไนซ์",
            loginButton: "เข้าสู่ระบบ",
            registerButton: "ลงทะเบียน"
        },
        // การพิสูจน์ตัวตน
        auth: {
            loginTitle: "เข้าสู่ระบบ",
            registerTitle: "ลงทะเบียน",
            email: "ที่อยู่อีเมล",
            password: "รหัสผ่าน",
            confirmPassword: "ยืนยันรหัสผ่าน",
            firstName: "ชื่อ",
            lastName: "นามสกุล",
            loginButton: "เข้าสู่ระบบ",
            registerButton: "ลงทะเบียน",
            forgotPassword: "ลืมรหัสผ่าน?",
            noAccount: "ยังไม่มีบัญชี?",
            hasAccount: "มีบัญชีแล้ว?",
            createAccount: "สร้างบัญชี",
            signIn: "เข้าสู่ระบบ",
            emailRequired: "จำเป็นต้องใส่อีเมล",
            passwordRequired: "จำเป็นต้องใส่รหัสผ่าน",
            emailInvalid: "ที่อยู่อีเมลไม่ถูกต้อง",
            passwordTooShort: "รหัสผ่านสั้นเกินไป",
            passwordsDontMatch: "รหัสผ่านไม่ตรงกัน",
            loginError: "ข้อผิดพลาดในการเข้าสู่ระบบ",
            registerError: "ข้อผิดพลาดในการลงทะเบียน",
            loginSuccess: "เข้าสู่ระบบสำเร็จ!",
            registerSuccess: "ลงทะเบียนสำเร็จ!"
        },
        // แดชบอร์ด
        dashboard: {
            title: "แดชบอร์ด",
            welcome: "ยินดีต้อนรับสู่แดชบอร์ด {name}!",
            subtitle: "จัดการชุดแฟลชการ์ดและเรียนรู้อย่างมีประสิทธิภาพ",
            newSet: "ชุดใหม่",
            settings: "การตั้งค่า",
            tagManager: "จัดการแท็ก",
            logout: "ออกจากระบบ",
            userMenu: "เมนูผู้ใช้",
            ownSets: "ชุดของฉัน",
            joinedSets: "ชุดที่เข้าร่วม",
            totalCards: "การ์ดทั้งหมด",
            mastered: "เรียนรู้แล้ว",
            ownSetsTitle: "ชุดของฉัน",
            joinedSetsTitle: "👥 ชุดที่เข้าร่วม",
            newSetButton: "สร้างชุดใหม่",
            noSets: "คุณยังไม่มีชุดการ์ด สร้างชุดแรกของคุณ!",
            cardCount: "การ์ด",
            masteredCount: "เรียนรู้แล้ว"
        },
        // การศึกษา
        study: {
            title: "ศึกษา",
            startStudy: "เริ่มการศึกษา",
            showAnswer: "แสดงคำตอบ",
            nextCard: "การ์ดถัดไป",
            prevCard: "การ์ดก่อนหน้า",
            again: "อีกครั้ง",
            hard: "ยาก",
            good: "ดี",
            easy: "ง่าย",
            studyComplete: "การศึกษาเสร็จสมบูรณ์!",
            cardsLeft: "การ์ดที่เหลือ: {count}",
            progress: "ความคืบหน้า: {current}/{total}"
        },
        // การตั้งค่า
        settings: {
            title: "⚙️ การตั้งค่า",
            interfaceLanguage: "🌍 ภาษาของ Snappy Cards",
            interfaceDescription: "การตั้งค่านี้กำหนดภาษาที่ใช้แสดงในอินเทอร์เฟซของ Snappy Cards",
            browserLanguage: "📱 ภาษาเบราว์เซอร์:",
            currentSetting: "⚙️ การตั้งค่าปัจจุบัน:",
            detectBrowser: "🔍 ตรวจจับภาษาเบราว์เซอร์อัตโนมัติ",
            languageUpdated: "อัปเดตภาษาแสดงผลแล้ว: {lang}",
            languageDetected: "ตรวจพบภาษาเบราว์เซอร์: {lang}",
            languageNotSupported: "ภาษาเบราว์เซอร์ ({lang}) ไม่รองรับ กรุณาเลือกจากรายการ!"
        },
        // ข้อความ
        messages: {
            success: {
                setCreated: "✅ สร้างชุดเรียบร้อยแล้ว!",
                setUpdated: "✅ อัปเดตชุดเรียบร้อยแล้ว!",
                setDeleted: "✅ ลบชุดเรียบร้อยแล้ว!"
            },
            error: {
                nameRequired: "จำเป็นต้องใส่ชื่อชุด!",
                createError: "เกิดข้อผิดพลาดในการสร้างชุด!",
                updateError: "เกิดข้อผิดพลาดในการบันทึกชุด!"
            }
        }
    }
};

// 🔧 Lokalizációs motor osztály
class SnappyI18n {
    constructor() {
        this.currentLanguage = this.detectLanguage();
        this.supportedLanguages = SUPPORTED_LANGUAGES;
        this.translations = TRANSLATIONS;
        this.observers = [];
        
        this.init();
    }

    // 🌐 Nyelv felismerés - IDEIGLENESEN MINDIG MAGYAR
    detectLanguage() {
        // ⚠️ LOKALIZÁCIÓ IDEIGLENESEN KIKAPCSOLVA - MINDIG MAGYAR
        console.log('🇭🇺 Lokalizáció ideiglenesen kikapcsolva - Magyar nyelv rögzítve');
        return 'hu';
        
        // EREDETI KÓD (később aktiválandó):
        // const savedLang = localStorage.getItem('snappy_user_language');
        // if (savedLang && SUPPORTED_LANGUAGES[savedLang]) return savedLang;
        // const browserLang = navigator.language.slice(0, 2);
        // if (SUPPORTED_LANGUAGES[browserLang]) return browserLang;
        // return 'hu';
    }

    // 🏁 Inicializálás
    init() {
        console.log(`🌍 Snappy I18n initialized with language: ${this.currentLanguage}`);
        
        // Automatikus frissítés DOM változáskor
        // this.observeDOM(); // ⚠️ Ideiglenesen kikapcsolva a villódzás miatt
        
        // Azonnal alkalmazza a fordításokat
        this.updateAllTexts();
    }

    // 👀 DOM változások figyelése (throttled to prevent flashing)
    observeDOM() {
        let updateTimeout = null;
        let isUpdating = false;
        
        // MutationObserver - automatikus újrafordítás új elemekhez
        const observer = new MutationObserver((mutations) => {
            // Skip if already updating to prevent infinite loops
            if (isUpdating) return;
            
            let shouldUpdate = false;
            
            mutations.forEach((mutation) => {
                if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                    mutation.addedNodes.forEach((node) => {
                        if (node.nodeType === 1 && (
                            node.hasAttribute('data-i18n') || 
                            node.querySelector('[data-i18n]')
                        )) {
                            shouldUpdate = true;
                        }
                    });
                }
            });

            if (shouldUpdate) {
                // Throttle updates to prevent flashing
                clearTimeout(updateTimeout);
                updateTimeout = setTimeout(() => {
                    isUpdating = true;
                    this.updateAllTexts();
                    // Reset after update
                    setTimeout(() => { isUpdating = false; }, 50);
                }, 200);
            }
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    // 🔤 Fordítás lekérése
    t(key, params = {}) {
        const keys = key.split('.');
        let value = this.translations[this.currentLanguage];
        
        for (const k of keys) {
            value = value?.[k];
        }
        
        if (typeof value === 'string' && params) {
            // Paraméterek helyettesítése {name} formátumban
            return value.replace(/\{(\w+)\}/g, (match, param) => params[param] || match);
        }
        
        return value || key; // Fallback a kulcsra ha nincs fordítás
    }

    // 🎨 Összes szöveg frissítése
    updateAllTexts() {
        let updatedCount = 0;
        
        // data-i18n attribútummal ellátott elemek
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.getAttribute('data-i18n');
            const translation = this.t(key);
            
            if (translation && translation !== key) {
                if (el.tagName === 'INPUT' && (el.type === 'text' || el.type === 'email' || el.type === 'password')) {
                    el.placeholder = translation;
                } else if (el.tagName === 'BUTTON' && el.innerHTML.includes('<span>')) {
                    // Gomb ikonnal - megtartja az ikont
                    const iconSpan = el.querySelector('span');
                    const iconHTML = iconSpan ? iconSpan.outerHTML : '';
                    el.innerHTML = iconHTML + '\n                        ' + translation;
                } else {
                    el.textContent = translation;
                }
                updatedCount++;
            }
        });

        // data-i18n-title attribútumok (tooltip-ek)
        document.querySelectorAll('[data-i18n-title]').forEach(el => {
            const key = el.getAttribute('data-i18n-title');
            const translation = this.t(key);
            
            if (translation && translation !== key) {
                el.title = translation;
                updatedCount++;
            }
        });

        // data-i18n-placeholder attribútumok
        document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
            const key = el.getAttribute('data-i18n-placeholder');
            const translation = this.t(key);
            
            if (translation && translation !== key) {
                el.placeholder = translation;
                updatedCount++;
            }
        });

        // Silent update to prevent console spam
        
        // Observer-ek értesítése
        this.notifyObservers();
    }

    // 🔧 Nyelv váltása - IDEIGLENESEN LETILTVA
    setLanguage(langCode) {
        // ⚠️ NYELVVÁLTÁS IDEIGLENESEN LETILTVA - MINDEN MAGYAR MARAD
        console.log(`🇭🇺 Nyelvváltás ideiglenesen letiltva. Kérés: ${langCode} → Magyar marad`);
        
        // Mindig magyar marad, nem változtatunk semmit
        this.currentLanguage = 'hu';
        localStorage.setItem('snappy_user_language', 'hu');
        
        // Szövegek nem változnak, mert már minden magyar
        return true;
        
        // EREDETI KÓD (később aktiválandó):
        // if (SUPPORTED_LANGUAGES[langCode]) {
        //     this.currentLanguage = langCode;
        //     localStorage.setItem('snappy_user_language', langCode);
        //     this.updateAllTexts();
        //     console.log(`🌍 Language changed to: ${langCode}`);
        //     return true;
        // } else {
        //     console.error(`❌ Language ${langCode} not supported.`);
        //     return false;
        // }
    }

    // 📝 Observer hozzáadása (oldal specifikus logikához)
    addObserver(callback) {
        this.observers.push(callback);
    }

    // 📢 Observer-ek értesítése
    notifyObservers() {
        this.observers.forEach(callback => {
            try {
                callback(this.currentLanguage);
            } catch (error) {
                console.error('I18n observer error:', error);
            }
        });
    }

    // 🎯 Speciális welcome üzenet frissítése
    updateWelcomeMessage(userName) {
        const welcomeEl = document.getElementById('welcomeTitle');
        if (welcomeEl) {
            const welcomeKey = this.currentLanguage === 'en' ? 
                'dashboard.welcome' : 
                this.currentLanguage === 'th' ? 
                'dashboard.welcome' : 
                'dashboard.welcome';
            
            const template = this.t(welcomeKey);
            welcomeEl.textContent = template.replace('{name}', userName || 'User');
        }
    }

    // 🌐 Nyelv lista lekérése
    getSupportedLanguages() {
        return this.supportedLanguages;
    }

    // 📊 Aktuális nyelv lekérése
    getCurrentLanguage() {
        return this.currentLanguage;
    }
}

// 🚀 Globális inicializálás
let snappyI18n;

// Automatikus inicializálás DOM betöltés után
document.addEventListener('DOMContentLoaded', () => {
    snappyI18n = new SnappyI18n();
    
    // Globális elérhetővé tétel
    window.snappyI18n = snappyI18n;
    window.t = (key, params) => snappyI18n.t(key, params);
    
    console.log('🌍 Snappy Cards I18n Engine Ready!');
});

// Export támogatás modulokhoz
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { SnappyI18n, TRANSLATIONS, SUPPORTED_LANGUAGES };
}