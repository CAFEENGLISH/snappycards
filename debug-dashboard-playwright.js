const { chromium } = require('playwright');

async function debugDashboard() {
    const browser = await chromium.launch({ 
        headless: false, 
        slowMo: 500,
        args: ['--disable-web-security', '--disable-features=VizDisplayCompositor']
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();

    // Capture all console messages
    page.on('console', msg => {
        console.log(`🔍 CONSOLE [${msg.type()}]:`, msg.text());
    });

    // Capture network failures
    page.on('requestfailed', request => {
        console.log(`❌ NETWORK FAILED: ${request.method()} ${request.url()} - ${request.failure()?.errorText}`);
    });

    // Capture API responses
    page.on('response', response => {
        const url = response.url();
        if (url.includes('supabase.co') || url.includes('render.com') || url.includes('localhost:8080')) {
            console.log(`📡 API Response: ${response.status()} ${response.url()}`);
        }
    });

    try {
        console.log('🚀 Starting debug session...');
        
        // Navigate to student dashboard
        console.log('📱 Loading student dashboard...');
        await page.goto('http://localhost:3000/student-dashboard.html', { 
            waitUntil: 'networkidle' 
        });

        // Wait a bit for any initial loading
        await page.waitForTimeout(2000);

        // Check if login form is visible (indicates not authenticated)
        const loginForm = page.locator('#loginForm');
        const isLoginVisible = await loginForm.isVisible().catch(() => false);
        
        if (isLoginVisible) {
            console.log('🔐 Login form detected - attempting login...');
            
            // Fill in credentials
            await page.fill('input[type="email"]', 'vidamkos@gmail.com');
            await page.fill('input[type="password"]', 'Palacs1nta');
            
            console.log('✅ Credentials filled, clicking login...');
            
            // Click login button
            await page.click('button[type="submit"]');
            
            // Wait for login response
            await page.waitForTimeout(3000);
        } else {
            console.log('ℹ️ No login form visible - checking authentication state...');
        }

        // Check authentication state
        const authState = await page.evaluate(() => {
            if (typeof window.supabaseClient !== 'undefined') {
                return window.supabaseClient.auth.getSession();
            }
            return { data: { session: null } };
        });
        
        console.log('🔑 Auth State:', authState.data?.session ? 'AUTHENTICATED' : 'NOT AUTHENTICATED');
        
        if (authState.data?.session) {
            console.log('👤 User ID:', authState.data.session.user.id);
            console.log('📧 Email:', authState.data.session.user.email);
        }

        // Wait for dashboard content to load
        console.log('⏳ Waiting for dashboard content...');
        await page.waitForTimeout(5000);

        // Check for flashcard sets
        const setsContainer = page.locator('.sets-container, #ownSetsContainer, [data-sets]');
        const setsExists = await setsContainer.count() > 0;
        
        console.log('📚 Sets container found:', setsExists);
        
        if (setsExists) {
            const setsCount = await page.locator('.set-card, .flashcard-set-card, [data-set-id]').count();
            console.log('🎴 Number of flashcard sets found:', setsCount);
            
            // Look for "konyha" specifically
            const konyhaSet = page.locator('text="konyha"');
            const konyhaExists = await konyhaSet.count() > 0;
            console.log('🔍 "konyha" set found:', konyhaExists);
            
            if (!konyhaExists) {
                console.log('❌ "konyha" set not found - checking all visible text...');
                const allText = await page.textContent('body');
                console.log('📄 Page contains "konyha":', allText.includes('konyha'));
            }
        }

        // Check for any error messages
        const errorMessages = await page.locator('.error, .alert-danger, [data-error]').allTextContents();
        if (errorMessages.length > 0) {
            console.log('⚠️ Error messages found:', errorMessages);
        }

        // Check network tab for 401s or other auth issues
        console.log('🔄 Checking for recent network issues...');
        
        // Force a data refresh to see current API calls
        await page.evaluate(() => {
            if (typeof loadSets === 'function') {
                console.log('🔄 Manually triggering loadSets...');
                loadSets();
            } else if (typeof initializeDashboard === 'function') {
                console.log('🔄 Manually triggering initializeDashboard...');
                initializeDashboard();
            }
        });

        // Wait for any additional API calls
        await page.waitForTimeout(5000);

        // Final check for sets data
        const finalSetsCheck = await page.evaluate(() => {
            const sets = document.querySelectorAll('.set-card, .flashcard-set-card, [data-set-id]');
            return {
                count: sets.length,
                titles: Array.from(sets).map(el => el.textContent?.trim() || 'No text'),
                hasKonyha: Array.from(sets).some(el => 
                    el.textContent?.toLowerCase().includes('konyha')
                )
            };
        });

        console.log('📊 Final sets analysis:', finalSetsCheck);

        console.log('✅ Debug session complete. Press Ctrl+C to exit or browser will stay open for manual inspection.');
        
        // Keep browser open for manual inspection
        await page.waitForTimeout(300000); // 5 minutes

    } catch (error) {
        console.error('❌ Debug session error:', error);
    } finally {
        console.log('🔄 Closing browser...');
        await browser.close();
    }
}

// Run the debug session
debugDashboard().catch(console.error);