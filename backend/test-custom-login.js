const axios = require('axios');

async function testCustomLogin() {
    const apiUrl = 'http://localhost:8080';
    const credentials = {
        email: 'vidamkos@gmail.com',
        password: 'Palacs1nta'
    };

    console.log('🔧 Testing custom login endpoint...');
    console.log(`📧 Email: ${credentials.email}`);
    console.log(`🔐 Password: ${credentials.password}`);

    try {
        const response = await axios.post(`${apiUrl}/custom-login`, credentials, {
            headers: {
                'Content-Type': 'application/json'
            }
        });

        console.log('✅ Custom login successful!');
        console.log('📋 Response data:', JSON.stringify(response.data, null, 2));

    } catch (error) {
        if (error.response) {
            console.error('❌ Login failed:', error.response.status);
            console.error('📋 Error data:', JSON.stringify(error.response.data, null, 2));
        } else {
            console.error('❌ Network error:', error.message);
            console.log('💡 Make sure the server is running on port 8080');
        }
    }
}

testCustomLogin();