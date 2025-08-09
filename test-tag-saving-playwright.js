const { chromium } = require('playwright');

async function testTagSaving() {
    const browser = await chromium.launch({ 
        headless: false, 
        slowMo: 500,
        args: ['--disable-web-security', '--disable-features=VizDisplayCompositor']
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();

    // Arrays to store all console messages and errors
    const consoleLogs = [];
    const networkErrors = [];
    const apiResponses = [];

    // Capture all console messages
    page.on('console', msg => {
        const logEntry = `[${new Date().toISOString()}] CONSOLE [${msg.type()}]: ${msg.text()}`;
        consoleLogs.push(logEntry);
        console.log(`🔍 ${logEntry}`);
    });

    // Capture network failures
    page.on('requestfailed', request => {
        const errorEntry = `[${new Date().toISOString()}] NETWORK FAILED: ${request.method()} ${request.url()} - ${request.failure()?.errorText}`;
        networkErrors.push(errorEntry);
        console.log(`❌ ${errorEntry}`);
    });

    // Capture API responses
    page.on('response', response => {
        const url = response.url();
        if (url.includes('supabase.co') || url.includes('render.com') || url.includes('localhost:8080')) {
            const responseEntry = `[${new Date().toISOString()}] API Response: ${response.status()} ${response.url()}`;
            apiResponses.push(responseEntry);
            console.log(`📡 ${responseEntry}`);
        }
    });

    // Capture JavaScript errors
    page.on('pageerror', error => {
        const errorEntry = `[${new Date().toISOString()}] PAGE ERROR: ${error.message}`;
        consoleLogs.push(errorEntry);
        console.log(`🚨 ${errorEntry}`);
    });

    try {
        console.log('🚀 Starting tag saving test...');
        
        // Step 1: Navigate to student dashboard
        console.log('📱 Loading student dashboard...');
        await page.goto('http://localhost:3000/student-dashboard.html', { 
            waitUntil: 'networkidle' 
        });

        await page.waitForTimeout(2000);

        // Step 2: Login if needed
        const loginForm = page.locator('#loginForm');
        const isLoginVisible = await loginForm.isVisible().catch(() => false);
        
        if (isLoginVisible) {
            console.log('🔐 Login form detected - attempting login...');
            
            await page.fill('input[type="email"]', 'vidamkos@gmail.com');
            await page.fill('input[type="password"]', 'Palacs1nta');
            
            console.log('✅ Credentials filled, clicking login...');
            await page.click('button[type="submit"]');
            await page.waitForTimeout(3000);
        } else {
            console.log('ℹ️ No login form visible');
        }

        // Wait for dashboard content to load
        console.log('⏳ Waiting for dashboard content...');
        await page.waitForTimeout(5000);

        // Step 3: Find and click on "konyha" flashcard set
        console.log('🔍 Looking for "konyha" flashcard set...');
        
        // Try multiple selectors for the konyha set
        const konyhaSelectors = [
            'text="konyha"',
            '[data-set-name*="konyha"]',
            '.set-card:has-text("konyha")',
            '.flashcard-set-card:has-text("konyha")',
            'div:has-text("konyha")'
        ];

        let konyhaFound = false;
        for (const selector of konyhaSelectors) {
            try {
                const konyhaElement = page.locator(selector).first();
                if (await konyhaElement.count() > 0) {
                    console.log(`✅ Found "konyha" set with selector: ${selector}`);
                    await konyhaElement.click();
                    konyhaFound = true;
                    break;
                }
            } catch (e) {
                console.log(`❌ Selector failed: ${selector} - ${e.message}`);
            }
        }

        if (!konyhaFound) {
            console.log('❌ "konyha" set not found. Checking all available sets...');
            const allSets = await page.locator('.set-card, .flashcard-set-card, [data-set-id]').allTextContents();
            console.log('📚 Available sets:', allSets);
            throw new Error('Could not find "konyha" flashcard set');
        }

        // Wait for the card list to load
        console.log('⏳ Waiting for card list to load...');
        await page.waitForTimeout(3000);

        // Step 4: Find and click edit on "konyhapult" card
        console.log('🔍 Looking for "konyhapult" card...');
        
        // Try multiple selectors for finding the card and its edit button
        const cardSelectors = [
            '.card-item:has-text("konyhapult")',
            '.flashcard:has-text("konyhapult")',
            '[data-card-front*="konyhapult"]',
            'div:has-text("konyhapult")'
        ];

        let cardFound = false;
        for (const selector of cardSelectors) {
            try {
                const cardElement = page.locator(selector).first();
                if (await cardElement.count() > 0) {
                    console.log(`✅ Found "konyhapult" card with selector: ${selector}`);
                    
                    // Look for edit button within or near the card
                    const editButtonSelectors = [
                        `${selector} button:has-text("Edit")`,
                        `${selector} .edit-btn`,
                        `${selector} [data-action="edit"]`,
                        `${selector} button[onclick*="edit"]`,
                        `${selector} .fa-edit`,
                        `${selector} .edit-card-btn`
                    ];

                    let editFound = false;
                    for (const editSelector of editButtonSelectors) {
                        try {
                            const editButton = page.locator(editSelector).first();
                            if (await editButton.count() > 0) {
                                console.log(`✅ Found edit button with selector: ${editSelector}`);
                                await editButton.click();
                                editFound = true;
                                break;
                            }
                        } catch (e) {
                            console.log(`❌ Edit selector failed: ${editSelector} - ${e.message}`);
                        }
                    }

                    if (editFound) {
                        cardFound = true;
                        break;
                    }
                }
            } catch (e) {
                console.log(`❌ Card selector failed: ${selector} - ${e.message}`);
            }
        }

        if (!cardFound) {
            console.log('❌ "konyhapult" card or edit button not found. Checking all available cards...');
            const allCards = await page.locator('.card-item, .flashcard, [data-card-front]').allTextContents();
            console.log('🎴 Available cards:', allCards);
            throw new Error('Could not find "konyhapult" card or its edit button');
        }

        // Wait for edit modal/form to load
        console.log('⏳ Waiting for edit form to load...');
        await page.waitForTimeout(2000);

        // Step 5: Add "belső helység" tag
        console.log('🏷️ Adding "belső helység" tag...');
        
        // Look for tag input field
        const tagInputSelectors = [
            'input[placeholder*="tag"]',
            'input[name*="tag"]',
            '#tags-input',
            '.tag-input',
            'input[data-tags]',
            '.tags-container input',
            'input[type="text"]:near(.tag, #tag)'
        ];

        let tagInputFound = false;
        for (const selector of tagInputSelectors) {
            try {
                const tagInput = page.locator(selector).first();
                if (await tagInput.count() > 0) {
                    console.log(`✅ Found tag input with selector: ${selector}`);
                    
                    // Clear existing content and add new tag
                    await tagInput.clear();
                    await tagInput.fill('belső helység');
                    
                    // Try to add the tag (might need to press Enter or click add button)
                    await tagInput.press('Enter');
                    await page.waitForTimeout(500);
                    
                    // Look for an add tag button
                    const addTagButton = page.locator('button:has-text("Add"), .add-tag-btn, [data-action="add-tag"]').first();
                    if (await addTagButton.count() > 0) {
                        await addTagButton.click();
                        console.log('✅ Clicked add tag button');
                    }
                    
                    tagInputFound = true;
                    break;
                }
            } catch (e) {
                console.log(`❌ Tag input selector failed: ${selector} - ${e.message}`);
            }
        }

        if (!tagInputFound) {
            console.log('❌ Tag input field not found. Looking for alternative tag adding methods...');
            
            // Check if there's already a tags section where we can add tags
            const existingTags = await page.locator('.tag, .chip, [data-tag]').allTextContents();
            console.log('🏷️ Existing tags found:', existingTags);
        }

        // Step 6: Save the card
        console.log('💾 Saving the card...');
        
        const saveButtonSelectors = [
            'button:has-text("Save")',
            'button:has-text("Update")',
            '.save-btn',
            '.save-card-btn',
            '[data-action="save"]',
            'button[type="submit"]',
            '.btn-primary:has-text("Save")'
        ];

        let saveFound = false;
        for (const selector of saveButtonSelectors) {
            try {
                const saveButton = page.locator(selector).first();
                if (await saveButton.count() > 0) {
                    console.log(`✅ Found save button with selector: ${selector}`);
                    await saveButton.click();
                    saveFound = true;
                    break;
                }
            } catch (e) {
                console.log(`❌ Save selector failed: ${selector} - ${e.message}`);
            }
        }

        if (!saveFound) {
            console.log('❌ Save button not found');
        }

        // Wait for save operation to complete
        console.log('⏳ Waiting for save operation to complete...');
        await page.waitForTimeout(3000);

        // Step 7: Verify the tag was saved
        console.log('✅ Verifying tag was saved...');
        
        // Check if we can see the tag in the UI
        const tagVerification = await page.evaluate(() => {
            const tags = Array.from(document.querySelectorAll('.tag, .chip, [data-tag]'))
                .map(el => el.textContent?.trim())
                .filter(Boolean);
            return {
                allTags: tags,
                hasBelsoHelyseg: tags.some(tag => tag.includes('belső helység') || tag.includes('belso helyseg'))
            };
        });

        console.log('🔍 Tag verification result:', tagVerification);

        console.log('✅ Test complete! Keeping browser open for 30 seconds for manual inspection...');
        
        // Keep browser open for inspection
        await page.waitForTimeout(30000);

    } catch (error) {
        console.error('❌ Test failed:', error.message);
        console.error('Stack:', error.stack);
    } finally {
        console.log('\n📊 === FINAL REPORT ===');
        console.log(`📝 Total console logs: ${consoleLogs.length}`);
        console.log(`🌐 Network errors: ${networkErrors.length}`);
        console.log(`📡 API responses: ${apiResponses.length}`);
        
        console.log('\n🔍 === CONSOLE LOGS ===');
        consoleLogs.forEach(log => console.log(log));
        
        if (networkErrors.length > 0) {
            console.log('\n❌ === NETWORK ERRORS ===');
            networkErrors.forEach(error => console.log(error));
        }
        
        if (apiResponses.length > 0) {
            console.log('\n📡 === API RESPONSES ===');
            apiResponses.forEach(response => console.log(response));
        }

        console.log('\n🔄 Closing browser...');
        await browser.close();
    }
}

// Run the test
testTagSaving().catch(console.error);