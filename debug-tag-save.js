const { chromium } = require('playwright');

async function debugTagSave() {
    const browser = await chromium.launch({ 
        headless: false, 
        slowMo: 1000,
        args: ['--disable-web-security', '--disable-features=VizDisplayCompositor']
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();

    // Arrays to store all logs
    const allLogs = [];
    const errors = [];
    const apiCalls = [];

    // Capture all console messages
    page.on('console', async msg => {
        const text = msg.text();
        const type = msg.type();
        const logEntry = {
            time: new Date().toISOString(),
            type: type,
            text: text,
            location: msg.location()
        };
        
        allLogs.push(logEntry);
        
        // Also try to get the actual values if it's an object
        try {
            const args = await Promise.all(msg.args().map(arg => arg.jsonValue().catch(() => 'Could not serialize')));
            if (args.length > 0) {
                logEntry.args = args;
            }
        } catch (e) {}
        
        console.log(`[${type.toUpperCase()}] ${text}`);
        
        if (type === 'error') {
            errors.push(logEntry);
        }
    });

    // Capture page errors
    page.on('pageerror', error => {
        const errorEntry = {
            time: new Date().toISOString(),
            message: error.message,
            stack: error.stack
        };
        errors.push(errorEntry);
        console.log('PAGE ERROR:', error.message);
    });

    // Capture network requests to Supabase
    page.on('request', request => {
        const url = request.url();
        if (url.includes('supabase.co')) {
            const reqInfo = {
                time: new Date().toISOString(),
                method: request.method(),
                url: url,
                headers: request.headers(),
                postData: request.postData()
            };
            apiCalls.push({ type: 'request', ...reqInfo });
            console.log(`API REQUEST: ${request.method()} ${url}`);
        }
    });

    // Capture responses
    page.on('response', async response => {
        const url = response.url();
        if (url.includes('supabase.co')) {
            let body = null;
            try {
                body = await response.text();
            } catch (e) {}
            
            const respInfo = {
                time: new Date().toISOString(),
                status: response.status(),
                url: url,
                body: body
            };
            apiCalls.push({ type: 'response', ...respInfo });
            console.log(`API RESPONSE: ${response.status()} ${url}`);
            if (response.status() >= 400 && body) {
                console.log('ERROR RESPONSE BODY:', body);
            }
        }
    });

    try {
        console.log('Starting tag save debug test...\n');
        
        // Navigate to dashboard
        await page.goto('http://localhost:3000/student-dashboard.html', { 
            waitUntil: 'networkidle' 
        });

        await page.waitForTimeout(2000);

        // Login if needed
        const loginForm = page.locator('#loginForm');
        if (await loginForm.isVisible().catch(() => false)) {
            console.log('Logging in...');
            await page.fill('input[type="email"]', 'vidamkos@gmail.com');
            await page.fill('input[type="password"]', 'Palacs1nta');
            await page.click('button[type="submit"]');
            await page.waitForTimeout(3000);
        }

        // Wait for dashboard to load
        await page.waitForTimeout(3000);

        // Click on LISTA icon in konyha set (not the card itself)
        console.log('\nLooking for LISTA icon in konyha set...');
        const konyhaSet = page.locator('.set-card').filter({ hasText: 'konyha' }).first();
        
        if (await konyhaSet.count() > 0) {
            console.log('Found konyha set, looking for LISTA icon...');
            
            // Look for the list/LISTA icon within the konyha set
            const listaIconSelectors = [
                '.set-card:has-text("konyha") .fa-list',
                '.set-card:has-text("konyha") .list-icon',
                '.set-card:has-text("konyha") button[data-action="list"]',
                '.set-card:has-text("konyha") button[onclick*="showCardsList"]',
                '.set-card:has-text("konyha") .icon-list',
                '.set-card:has-text("konyha") [title*="list"]',
                '.set-card:has-text("konyha") [title*="Lista"]',
                '.set-card:has-text("konyha") .lucide-list'
            ];
            
            let listaIconFound = false;
            for (const selector of listaIconSelectors) {
                try {
                    const listaIcon = page.locator(selector).first();
                    if (await listaIcon.count() > 0) {
                        console.log(`✅ Found LISTA icon with selector: ${selector}`);
                        await listaIcon.click();
                        listaIconFound = true;
                        break;
                    }
                } catch (e) {
                    console.log(`❌ LISTA icon selector failed: ${selector} - ${e.message}`);
                }
            }
            
            if (!listaIconFound) {
                // If no icon found, let's inspect the set structure
                console.log('❌ LISTA icon not found. Inspecting set structure...');
                const setStructure = await konyhaSet.innerHTML();
                console.log('Set HTML structure:', setStructure);
                
                // Try clicking on any button within the set
                const anyButton = konyhaSet.locator('button').first();
                if (await anyButton.count() > 0) {
                    console.log('Trying to click first button in set...');
                    await anyButton.click();
                } else {
                    console.log('No buttons found in set, clicking on set itself...');
                    await konyhaSet.click();
                }
            }
        } else {
            console.log('❌ Konyha set not found');
        }

        await page.waitForTimeout(3000);

        // Look for konyhapult card and click edit
        console.log('\nLooking for konyhapult card...');
        
        // First, let's see what's on the page
        const cardsVisible = await page.evaluate(() => {
            const cards = document.querySelectorAll('.card-item, .flashcard-item, [data-card-id]');
            return Array.from(cards).map(card => ({
                text: card.textContent,
                id: card.getAttribute('data-card-id'),
                classes: card.className
            }));
        });
        console.log('Cards visible:', JSON.stringify(cardsVisible, null, 2));

        // Try to find and click edit button for konyhapult
        const konyhapultCard = page.locator('.card-item, .flashcard-item').filter({ hasText: 'konyhapult' }).first();
        if (await konyhapultCard.count() > 0) {
            // Look for edit button within the card
            const editBtn = konyhapultCard.locator('button').filter({ hasText: /edit|szerkeszt/i }).first();
            if (await editBtn.count() > 0) {
                console.log('Clicking edit button...');
                await editBtn.click();
            } else {
                // Try icon button
                const iconBtn = konyhapultCard.locator('.fa-edit, .fa-pencil, [onclick*="edit"]').first();
                if (await iconBtn.count() > 0) {
                    await iconBtn.click();
                }
            }
        }

        await page.waitForTimeout(2000);

        // Check if edit modal is open
        const editModal = await page.evaluate(() => {
            const modals = document.querySelectorAll('.modal.show, #editCardModal, [id*="edit"][id*="modal"]');
            return {
                modalFound: modals.length > 0,
                modalIds: Array.from(modals).map(m => m.id),
                visibleInputs: Array.from(document.querySelectorAll('input:not([type="hidden"])')).map(i => ({
                    name: i.name,
                    id: i.id,
                    placeholder: i.placeholder,
                    value: i.value
                }))
            };
        });
        console.log('Edit modal state:', JSON.stringify(editModal, null, 2));

        // Try to add tag
        console.log('\nTrying to add tag...');
        
        // Look for tag input
        const tagInput = page.locator('#cardTags, #tags-input, input[placeholder*="tag"], input[placeholder*="Tag"]').first();
        if (await tagInput.count() > 0) {
            console.log('Found tag input, typing "belső helység"...');
            await tagInput.click();
            await tagInput.fill('belső helység');
            await page.waitForTimeout(500);
            
            // Try pressing Enter
            await tagInput.press('Enter');
            await page.waitForTimeout(1000);
            
            // Check if tag was added to UI
            const tagsAfterAdd = await page.evaluate(() => {
                const tags = document.querySelectorAll('.tag, .chip, .badge, [data-tag]');
                return Array.from(tags).map(t => t.textContent);
            });
            console.log('Tags after adding:', tagsAfterAdd);
        }

        // Try to save
        console.log('\nTrying to save...');
        const saveBtn = page.locator('button').filter({ hasText: /save|ment|update/i }).first();
        if (await saveBtn.count() > 0) {
            console.log('Clicking save button...');
            await saveBtn.click();
            await page.waitForTimeout(3000);
        }

        // Check final state
        const finalState = await page.evaluate(() => {
            return {
                modalStillOpen: document.querySelector('.modal.show') !== null,
                errors: Array.from(document.querySelectorAll('.error, .alert-danger')).map(e => e.textContent),
                successMessages: Array.from(document.querySelectorAll('.success, .alert-success')).map(e => e.textContent)
            };
        });
        console.log('Final state:', JSON.stringify(finalState, null, 2));

        console.log('\n=== SUMMARY ===');
        console.log(`Total console logs: ${allLogs.length}`);
        console.log(`Errors found: ${errors.length}`);
        console.log(`API calls made: ${apiCalls.length}`);

        if (errors.length > 0) {
            console.log('\n=== ERRORS ===');
            errors.forEach(err => {
                console.log(`[${err.time}] ${err.message || err.text}`);
                if (err.stack) console.log(err.stack);
            });
        }

        // Look for specific issues
        const relevantLogs = allLogs.filter(log => 
            log.text.toLowerCase().includes('tag') ||
            log.text.toLowerCase().includes('category') ||
            log.text.toLowerCase().includes('error') ||
            log.text.toLowerCase().includes('fail')
        );

        if (relevantLogs.length > 0) {
            console.log('\n=== RELEVANT LOGS ===');
            relevantLogs.forEach(log => {
                console.log(`[${log.type}] ${log.text}`);
                if (log.args) console.log('  Args:', log.args);
            });
        }

        // Check failed API calls
        const failedAPIs = apiCalls.filter(call => 
            call.type === 'response' && call.status >= 400
        );

        if (failedAPIs.length > 0) {
            console.log('\n=== FAILED API CALLS ===');
            failedAPIs.forEach(call => {
                console.log(`${call.status} ${call.url}`);
                if (call.body) {
                    try {
                        const parsed = JSON.parse(call.body);
                        console.log('  Error:', parsed.message || parsed.error || call.body);
                    } catch {
                        console.log('  Body:', call.body);
                    }
                }
            });
        }

        // Keep browser open for inspection
        console.log('\nKeeping browser open for 30 seconds for manual inspection...');
        await page.waitForTimeout(30000);

    } catch (error) {
        console.error('Test failed:', error);
    } finally {
        await browser.close();
        
        // Save detailed logs to file
        const fs = require('fs');
        const logData = {
            timestamp: new Date().toISOString(),
            allLogs,
            errors,
            apiCalls
        };
        fs.writeFileSync('tag-debug-log.json', JSON.stringify(logData, null, 2));
        console.log('\nDetailed logs saved to tag-debug-log.json');
    }
}

debugTagSave().catch(console.error);