// Test script to debug matchmaking API response
const testUserId = 'cLh6b1aN0vaNamSsT7RFFsjE2kl1';

async function testMatchmakingAPI() {
  try {
    console.log('🧪 Testing matchmaking API...');
    
    const response = await fetch(`http://localhost:5000/api/matchmaking/${testUserId}/potential-matches?limit=10&excludeViewed=true`);
    
    console.log('📡 Response status:', response.status);
    console.log('📋 Response headers:', Object.fromEntries(response.headers.entries()));
    
    if (response.ok) {
      const text = await response.text();
      console.log('📄 Raw response text (first 500 chars):', text.substring(0, 500));
      
      try {
        const data = JSON.parse(text);
        console.log('✅ JSON parsed successfully');
        console.log('📊 Response structure:', {
          success: data.success,
          matchesCount: data.matches?.length,
          totalFound: data.totalFound,
          firstMatchKeys: data.matches?.[0] ? Object.keys(data.matches[0]) : null
        });
        
        // Check if matches have required fields
        if (data.matches && data.matches.length > 0) {
          const firstMatch = data.matches[0];
          console.log('🔍 First match profile structure:', {
            hasUser: !!firstMatch.user,
            hasFirstName: !!firstMatch.firstName,
            hasSkillLevel: !!firstMatch.skillLevel,
            hasPreferredGameTypes: !!firstMatch.preferredGameTypes,
            allKeys: Object.keys(firstMatch)
          });
        }
        
      } catch (parseError) {
        console.error('❌ JSON parse error:', parseError);
        console.log('📄 Raw text that failed to parse:', text);
      }
    } else {
      console.error('❌ HTTP error:', response.status, response.statusText);
      const errorText = await response.text();
      console.log('📄 Error response:', errorText);
    }
    
  } catch (error) {
    console.error('❌ Network/fetch error:', error);
  }
}

// Run the test
testMatchmakingAPI();
