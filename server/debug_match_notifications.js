// debug_match_notifications.js - Debug notification creation
const axios = require('axios');

const API_BASE = 'http://localhost:5000/api';

async function debugNotificationCreation() {
  console.log('🔍 Debugging Notification Creation...');
  console.log('====================================');

  try {
    // Test user IDs
    const user1 = 'alice-test-456';
    const user2 = 'bob-test-789';

    console.log('\n1. Checking if test profiles exist...');
    
    try {
      const profile1 = await axios.get(`${API_BASE}/profiles/${user1}`);
      console.log(`✅ User 1 profile exists: ${profile1.data.profile.firstName} ${profile1.data.profile.lastName}`);
    } catch (error) {
      console.log(`❌ User 1 profile not found. Creating...`);
      await axios.post(`${API_BASE}/test/create-multiple-profiles`);
      console.log('✅ Test profiles created');
    }

    try {
      const profile2 = await axios.get(`${API_BASE}/profiles/${user2}`);
      console.log(`✅ User 2 profile exists: ${profile2.data.profile.firstName} ${profile2.data.profile.lastName}`);
    } catch (error) {
      console.log(`❌ User 2 profile not found. Creating...`);
      await axios.post(`${API_BASE}/test/create-multiple-profiles`);
      console.log('✅ Test profiles created');
    }

    console.log('\n2. Clearing any existing likes/matches...');
    
    // Clear existing likes (this would require an endpoint to clear likes)
    // For now, we'll just check current state
    
    console.log('\n3. Checking current notification state...');
    const currentNotifications1 = await axios.get(`${API_BASE}/notifications/${user1}`);
    const currentNotifications2 = await axios.get(`${API_BASE}/notifications/${user2}`);
    
    console.log(`📱 User 1 current notifications: ${currentNotifications1.data.notifications.length}`);
    console.log(`📱 User 2 current notifications: ${currentNotifications2.data.notifications.length}`);

    console.log('\n4. Creating a test notification manually...');
    const testNotification = await axios.post(`${API_BASE}/notifications`, {
      userId: user1,
      type: 'test',
      relatedUserId: user2,
      message: 'This is a test notification to verify the system works'
    });
    console.log(`✅ Test notification created: ${testNotification.data.notification._id}`);

    // Check if it appears
    const afterTest = await axios.get(`${API_BASE}/notifications/${user1}`);
    console.log(`📱 User 1 notifications after test: ${afterTest.data.notifications.length}`);

    console.log('\n5. Attempting match creation with detailed logging...');
    
    console.log('   Step 5a: User 1 likes User 2...');
    const like1Response = await axios.post(`${API_BASE}/matchmaking/action`, {
      userId: user1,
      targetUserId: user2,
      action: 'like'
    });
    console.log(`   Result: ${JSON.stringify(like1Response.data)}`);

    console.log('   Step 5b: User 2 likes User 1 back...');
    const like2Response = await axios.post(`${API_BASE}/matchmaking/action`, {
      userId: user2,
      targetUserId: user1,
      action: 'like'
    });
    console.log(`   Result: ${JSON.stringify(like2Response.data)}`);

    console.log('\n6. Final notification check...');
    const finalNotifications1 = await axios.get(`${API_BASE}/notifications/${user1}`);
    const finalNotifications2 = await axios.get(`${API_BASE}/notifications/${user2}`);
    
    console.log(`📱 User 1 final notifications: ${finalNotifications1.data.notifications.length}`);
    console.log(`📱 User 2 final notifications: ${finalNotifications2.data.notifications.length}`);
    
    finalNotifications1.data.notifications.forEach((notif, index) => {
      console.log(`   User 1 #${index + 1}: [${notif.type}] ${notif.message}`);
    });
    
    finalNotifications2.data.notifications.forEach((notif, index) => {
      console.log(`   User 2 #${index + 1}: [${notif.type}] ${notif.message}`);
    });

    // Clean up test notification
    await axios.delete(`${API_BASE}/notifications/${testNotification.data.notification._id}`);
    console.log('✅ Test notification cleaned up');

  } catch (error) {
    console.error('❌ Debug failed:', error.response?.data || error.message);
  }
}

// Run the debug
debugNotificationCreation();
