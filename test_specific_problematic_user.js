// Test specifically the problematic user from MongoDB logs
const http = require('http');

const userId = 'HvflhVZfY9b4XJNdwznaA2nzFY02'; // The user from MongoDB logs

console.log('🧪 Testing problematic user specifically...');

const options = {
  hostname: 'localhost',
  port: 5000,
  path: `/api/matchmaking/${userId}/potential-matches`,
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  }
};

const req = http.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const response = JSON.parse(data);
      console.log('📊 Response success:', response.success);
      console.log('📦 Number of matches:', response.matches?.length || 0);
      
      if (response.matches && response.matches.length > 0) {
        // Check each match for potential issues
        response.matches.forEach((match, index) => {
          console.log(`\n--- Match ${index} Analysis ---`);
          console.log('📋 Keys:', Object.keys(match));
          
          // Check user field
          console.log('👤 User field:', match.user);
          if (match.user) {
            console.log('👤 User.id:', match.user.id, '(type:', typeof match.user.id, ', length:', match.user.id?.length || 0, ')');
            console.log('👤 User.email:', match.user.email, '(type:', typeof match.user.email, ', length:', match.user.email?.length || 0, ')');
          }
          
          // Check profile fields
          console.log('🏷️ firstName:', match.firstName, '(type:', typeof match.firstName, ')');
          console.log('🏷️ lastName:', match.lastName, '(type:', typeof match.lastName, ')');
          
          // Check for any empty strings or suspicious values
          if (match.user?.id === '' || match.user?.email === '') {
            console.log('⚠️ WARNING: Empty string detected in user fields!');
          }
          
          if (!match.firstName) {
            console.log('⚠️ WARNING: Missing or falsy firstName!');
          }
        });
      }
    } catch (error) {
      console.error('❌ Error parsing response:', error);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Request error:', error);
});

req.end();
