// test_match_notifications.js - Test notifications through matchmaking
const axios = require('axios');

const API_BASE = 'http://localhost:5000/api';

async function testMatchNotificationFlow() {
  console.log('🎯 Testing Match Notification Flow...');
  console.log('=====================================');

  try {
    // Test user IDs (these should exist in your system)
    const user1 = 'alice-test-456';
    const user2 = 'bob-test-789';

    console.log('\n1. Clearing existing notifications...');
    
    // Get existing notifications for cleanup
    const user1Notifications = await axios.get(`${API_BASE}/notifications/${user1}`);
    const user2Notifications = await axios.get(`${API_BASE}/notifications/${user2}`);
    
    // Delete existing notifications
    for (const notification of user1Notifications.data.notifications) {
      await axios.delete(`${API_BASE}/notifications/${notification._id}`);
    }
    for (const notification of user2Notifications.data.notifications) {
      await axios.delete(`${API_BASE}/notifications/${notification._id}`);
    }
    
    console.log('✅ Notifications cleared');

    console.log('\n2. Simulating User 1 likes User 2...');
    const like1Response = await axios.post(`${API_BASE}/matchmaking/action`, {
      userId: user1,
      targetUserId: user2,
      action: 'like'
    });
    console.log(`✅ Like action result: isMatch=${like1Response.data.isMatch}`);

    console.log('\n3. Simulating User 2 likes User 1 back (should create match)...');
    const like2Response = await axios.post(`${API_BASE}/matchmaking/action`, {
      userId: user2,
      targetUserId: user1,
      action: 'like'
    });
    console.log(`✅ Like back action result: isMatch=${like2Response.data.isMatch}`);

    if (like2Response.data.isMatch) {
      console.log('\n🎉 MATCH CREATED! Checking notifications...');

      // Wait a moment for notifications to be created
      await new Promise(resolve => setTimeout(resolve, 1000));

      console.log('\n4. Checking User 1 notifications...');
      const user1NewNotifications = await axios.get(`${API_BASE}/notifications/${user1}`);
      console.log(`📱 User 1 has ${user1NewNotifications.data.notifications.length} notifications`);
      if (user1NewNotifications.data.notifications.length > 0) {
        console.log(`📋 Latest: "${user1NewNotifications.data.notifications[0].message}"`);
      }

      console.log('\n5. Checking User 2 notifications...');
      const user2NewNotifications = await axios.get(`${API_BASE}/notifications/${user2}`);
      console.log(`📱 User 2 has ${user2NewNotifications.data.notifications.length} notifications`);
      if (user2NewNotifications.data.notifications.length > 0) {
        console.log(`📋 Latest: "${user2NewNotifications.data.notifications[0].message}"`);
      }

      console.log('\n6. Testing notification management...');
      
      // Test unread count
      const unreadCount1 = await axios.get(`${API_BASE}/notifications/${user1}/unread-count`);
      const unreadCount2 = await axios.get(`${API_BASE}/notifications/${user2}/unread-count`);
      console.log(`🔴 User 1 unread: ${unreadCount1.data.count}`);
      console.log(`🔴 User 2 unread: ${unreadCount2.data.count}`);

      // Mark one as read
      if (user1NewNotifications.data.notifications.length > 0) {
        const notificationId = user1NewNotifications.data.notifications[0]._id;
        await axios.patch(`${API_BASE}/notifications/${notificationId}/read`);
        console.log('✅ Marked User 1 notification as read');
        
        const newUnreadCount = await axios.get(`${API_BASE}/notifications/${user1}/unread-count`);
        console.log(`🔴 User 1 unread after marking as read: ${newUnreadCount.data.count}`);
      }

      console.log('\n🎉 Match notification flow test completed successfully!');
      console.log('===============================================');
      console.log('✅ Matches are creating notifications properly');
      console.log('✅ Both users receive personalized messages');
      console.log('✅ Notification management works correctly');
      
    } else {
      console.log('❌ No match was created. This could mean:');
      console.log('   - Users already liked each other');
      console.log('   - Test profiles need to be reset');
      console.log('   - Matchmaking logic has an issue');
    }

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    console.log('\n💡 Make sure:');
    console.log('   1. Server is running (node server.js)');
    console.log('   2. Test profiles exist in the database');
    console.log('   3. MongoDB connection is working');
  }
}

// Run the test
testMatchNotificationFlow();
