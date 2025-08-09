const { chromium } = require('playwright');

async function debugUIRendering() {
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
        const text = msg.text();
        if (text.includes('DEBUG') || text.includes('ownSets') || text.includes('konyha') || text.includes('loadOwnSets')) {
            console.log(`🔍 CONSOLE [${msg.type()}]:`, text);
        }
    });

    try {
        console.log('🚀 Starting UI debugging session...');
        
        // Navigate to student dashboard
        await page.goto('http://localhost:3000/student-dashboard.html', { 
            waitUntil: 'networkidle' 
        });

        // Wait a bit and login
        await page.waitForTimeout(2000);

        const loginForm = page.locator('#loginForm');
        const isLoginVisible = await loginForm.isVisible().catch(() => false);
        
        if (isLoginVisible) {
            console.log('🔐 Logging in...');
            await page.fill('input[type="email"]', 'vidamkos@gmail.com');
            await page.fill('input[type="password"]', 'Palacs1nta');
            await page.click('button[type="submit"]');
            await page.waitForTimeout(5000);
        }

        // Wait for dashboard to load
        await page.waitForTimeout(8000);

        // Check DOM structure
        console.log('🏗️ Checking DOM structure...');
        
        const ownSetsGrid = await page.locator('#ownSetsGrid').count();
        console.log('📍 ownSetsGrid found:', ownSetsGrid > 0);
        
        if (ownSetsGrid > 0) {
            // Check if grid has content
            const gridContent = await page.locator('#ownSetsGrid').innerHTML();
            console.log('📄 Grid content length:', gridContent.length);
            console.log('📄 Grid contains "konyha":', gridContent.includes('konyha'));
            
            // Check for set cards
            const setCards = await page.locator('#ownSetsGrid .set-card, #ownSetsGrid .flashcard-set-card').count();
            console.log('🎴 Set cards found:', setCards);
            
            if (setCards === 0) {
                console.log('❌ No set cards found - checking for other content...');
                console.log('🔍 Grid HTML preview:', gridContent.substring(0, 500));
            }
        }

        // Check dashboardData in browser context
        console.log('🔍 Checking dashboardData...');
        const dashboardData = await page.evaluate(() => {
            return typeof window.dashboardData !== 'undefined' ? {
                ownSetsCount: window.dashboardData?.ownSets?.length || 'undefined',
                joinedSetsCount: window.dashboardData?.joinedSets?.length || 'undefined',
                firstOwnSet: window.dashboardData?.ownSets?.[0]?.title || 'no sets'
            } : 'dashboardData not available';
        });
        console.log('📊 Dashboard data:', dashboardData);

        // Force a manual call to loadOwnSets
        console.log('🔄 Manually triggering loadOwnSets...');
        await page.evaluate(() => {
            if (typeof loadOwnSets === 'function') {
                console.log('🔄 Calling loadOwnSets...');
                loadOwnSets();
            } else {
                console.log('❌ loadOwnSets function not available');
            }
        });

        await page.waitForTimeout(3000);

        // Final check
        const finalSetCards = await page.locator('#ownSetsGrid .set-card, #ownSetsGrid .flashcard-set-card, #ownSetsGrid [data-set-id]').count();
        console.log('🎯 Final set cards count:', finalSetCards);

        // Get final grid content
        const finalGridContent = await page.locator('#ownSetsGrid').innerHTML();
        if (finalGridContent.includes('konyha')) {
            console.log('✅ SUCCESS: konyha set found in final grid content!');
        } else {
            console.log('❌ konyha set still not in grid content');
            console.log('🔍 Grid preview:', finalGridContent.substring(0, 300));
        }

        // Take screenshot for inspection
        await page.screenshot({ path: 'dashboard-debug.png', fullPage: true });
        console.log('📸 Screenshot saved as dashboard-debug.png');

        console.log('✅ UI Debug complete. Press Ctrl+C to exit or inspect manually.');
        
        // Keep browser open for manual inspection
        await page.waitForTimeout(60000); // 1 minute

    } catch (error) {
        console.error('❌ UI Debug error:', error);
    } finally {
        await browser.close();
    }
}

debugUIRendering().catch(console.error);