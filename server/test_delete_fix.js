// Test DELETE endpoints after JSON middleware fix
const http = require('http');

// Test function
async function testDelete(endpoint, description) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: endpoint,
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json'
      }
    };

    console.log(`\n🧪 Testing: ${description}`);
    console.log(`📍 Endpoint: DELETE ${endpoint}`);

    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`✅ Status: ${res.statusCode}`);
        console.log(`📝 Response: ${data}`);
        resolve({ status: res.statusCode, data });
      });
    });

    req.on('error', (error) => {
      console.log(`❌ Error: ${error.message}`);
      reject(error);
    });

    // Send empty body (like the Flutter app does)
    req.end();
  });
}

async function runTests() {
  console.log('🚀 Testing DELETE endpoints...\n');
  
  try {
    // Test venue removal (should work now)
    await testDelete('/api/wishlists/687b64bc34bbe8b70ce30127/venues/7', 'Remove venue from wishlist');
    
    // Test wishlist deletion (should work now)  
    await testDelete('/api/wishlists/687b64bc34bbe8b70ce30127', 'Delete wishlist');
    
    console.log('\n✅ All tests completed!');
  } catch (error) {
    console.log('\n❌ Test failed:', error.message);
  }
}

runTests();
