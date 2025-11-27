// Test the exact user that's failing from the MongoDB logs
const fetch = require('node-fetch');

async function testSpecificUser() {
    try {
        console.log('🧪 Testing specific user from MongoDB logs...');
        
        const userId = 'HvflhVZfY9b4XJNdwznaA2nzFY02'; // From your MongoDB logs
        const url = `http://localhost:5000/api/matchmaking/potential-matches/${userId}`;
        
        console.log(`🔗 Fetching: ${url}`);
        
        const response = await fetch(url);
        const data = await response.json();
        
        console.log('📊 Response Status:', response.status);
        console.log('✅ Response Success:', data.success);
        console.log('📦 Number of matches:', data.matches?.length || 0);
        
        if (data.matches && data.matches.length > 0) {
            // Check the first few matches for structure
            console.log('\n🔍 Analyzing first match structure:');
            const firstMatch = data.matches[0];
            console.log('📋 Available fields:', Object.keys(firstMatch));
            console.log('👤 User field present:', !!firstMatch.user);
            console.log('👤 User structure:', firstMatch.user ? Object.keys(firstMatch.user) : 'No user field');
            console.log('🏷️ firstName:', firstMatch.firstName);
            console.log('🏷️ lastName:', firstMatch.lastName);
            console.log('📧 User id:', firstMatch.user?.id);
            console.log('📧 User email:', firstMatch.user?.email);
            
            // Check for any missing critical fields
            const requiredFields = ['firstName', 'skillLevel', 'preferredGameTypes'];
            const userRequiredFields = ['id', 'email'];
            
            console.log('\n🔍 Checking required PlayerProfile fields:');
            requiredFields.forEach(field => {
                const value = firstMatch[field];
                console.log(`  ${field}: ${value !== undefined ? '✅' : '❌'} (${typeof value}) = ${value}`);
            });
            
            console.log('\n🔍 Checking required User fields:');
            if (firstMatch.user) {
                userRequiredFields.forEach(field => {
                    const value = firstMatch.user[field];
                    console.log(`  user.${field}: ${value !== undefined && value !== null && value !== '' ? '✅' : '❌'} (${typeof value}) = ${value}`);
                });
            } else {
                console.log('❌ No user field found!');
            }
        }
        
    } catch (error) {
        console.error('❌ Error testing user:', error.message);
    }
}

testSpecificUser();
