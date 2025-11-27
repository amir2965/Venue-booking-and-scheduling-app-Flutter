// Test script to test PlayerProfile parsing with actual API data
const testUserId = 'cLh6b1aN0vaNamSsT7RFFsjE2kl1';

async function testPlayerProfileParsing() {
  try {
    console.log('🧪 Testing PlayerProfile parsing with real API data...');
    
    const response = await fetch(`http://localhost:5000/api/matchmaking/${testUserId}/potential-matches?limit=1&excludeViewed=true`);
    
    if (response.ok) {
      const data = await response.json();
      
      if (data.success && data.matches.length > 0) {
        const firstMatch = data.matches[0];
        console.log('📊 First match data:');
        console.log(JSON.stringify(firstMatch, null, 2));
        
        // Check required fields for PlayerProfile
        const requiredFields = {
          'user': firstMatch.user,
          'firstName': firstMatch.firstName,
          'lastName': firstMatch.lastName,
          'bio': firstMatch.bio,
          'skillLevel': firstMatch.skillLevel,
          'skillTier': firstMatch.skillTier,
          'preferredGameTypes': firstMatch.preferredGameTypes,
          'availability': firstMatch.availability
        };
        
        console.log('\n🔍 Required field check:');
        Object.entries(requiredFields).forEach(([key, value]) => {
          const status = value !== undefined && value !== null ? '✅' : '❌';
          console.log(`${status} ${key}: ${typeof value} = ${value}`);
        });
        
        // Check user object specifically
        if (firstMatch.user) {
          console.log('\n👤 User object fields:');
          Object.entries(firstMatch.user).forEach(([key, value]) => {
            const status = value !== undefined && value !== null ? '✅' : '❌';
            console.log(`${status} user.${key}: ${typeof value} = ${value}`);
          });
        } else {
          console.log('❌ User object is missing!');
        }
        
      } else {
        console.log('❌ No matches found in response');
      }
    } else {
      console.error('❌ API request failed:', response.status);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run the test
testPlayerProfileParsing();
