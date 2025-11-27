// test_notifications.js - Comprehensive test script for notification endpoints
const axios = require('axios');

const API_BASE = 'http://localhost:5000/api';

// Test data
const testUsers = {
  alice: 'alice-test-456',
  bob: 'bob-test-789',
  charlie: 'charlie-test-101'
};

// Helper function to make API calls
async function apiCall(method, endpoint, data = null) {
  try {
    const config = {
      method,
      url: `${API_BASE}${endpoint}`,
      headers: { 'Content-Type': 'application/json' }
    };
    
    if (data) {
      config.data = data;
    }
    
    const response = await axios(config);
    return { success: true, data: response.data, status: response.status };
  } catch (error) {
    return { 
      success: false, 
      error: error.response?.data || error.message,
      status: error.response?.status || 500
    };
  }
}

// Test functions
async function testHealthCheck() {
  console.log('\n🏥 Testing Health Check...');
  const result = await apiCall('GET', '/health');
  
  if (result.success && result.data.status === 'ok') {
    console.log('✅ Health check passed');
    return true;
  } else {
    console.log('❌ Health check failed:', result.error);
    return false;
  }
}

async function testCreateNotification() {
  console.log('\n📝 Testing Create Notification...');
  
  const notificationData = {
    userId: testUsers.alice,
    type: 'match',
    relatedUserId: testUsers.bob,
    message: 'You have a new match with Bob Smith!',
    isRead: false
  };
  
  const result = await apiCall('POST', '/notifications', notificationData);
  
  if (result.success && result.status === 201) {
    console.log('✅ Notification created successfully');
    console.log('📋 Notification ID:', result.data.notification._id);
    return result.data.notification._id;
  } else {
    console.log('❌ Failed to create notification:', result.error);
    return null;
  }
}

async function testGetNotifications(userId) {
  console.log(`\n📱 Testing Get Notifications for user: ${userId}...`);
  
  const result = await apiCall('GET', `/notifications/${userId}`);
  
  if (result.success) {
    console.log('✅ Retrieved notifications successfully');
    console.log('📊 Notification count:', result.data.notifications.length);
    console.log('🔴 Unread count:', result.data.unreadCount);
    
    if (result.data.notifications.length > 0) {
      console.log('📋 Sample notification:', {
        id: result.data.notifications[0]._id,
        type: result.data.notifications[0].type,
        message: result.data.notifications[0].message,
        isRead: result.data.notifications[0].isRead
      });
    }
    return result.data.notifications;
  } else {
    console.log('❌ Failed to get notifications:', result.error);
    return [];
  }
}

async function testGetUnreadCount(userId) {
  console.log(`\n🔢 Testing Get Unread Count for user: ${userId}...`);
  
  const result = await apiCall('GET', `/notifications/${userId}/unread-count`);
  
  if (result.success) {
    console.log('✅ Retrieved unread count successfully');
    console.log('🔴 Unread count:', result.data.count);
    return result.data.count;
  } else {
    console.log('❌ Failed to get unread count:', result.error);
    return -1;
  }
}

async function testMarkAsRead(notificationId) {
  console.log(`\n✅ Testing Mark as Read for notification: ${notificationId}...`);
  
  const result = await apiCall('PATCH', `/notifications/${notificationId}/read`);
  
  if (result.success) {
    console.log('✅ Notification marked as read successfully');
    console.log('📋 Updated notification read status:', result.data.notification.isRead);
    return true;
  } else {
    console.log('❌ Failed to mark notification as read:', result.error);
    return false;
  }
}

async function testMarkAllAsRead(userId) {
  console.log(`\n✅ Testing Mark All as Read for user: ${userId}...`);
  
  const result = await apiCall('PATCH', `/notifications/${userId}/mark-all-read`);
  
  if (result.success) {
    console.log('✅ All notifications marked as read successfully');
    console.log('📊 Modified count:', result.data.modifiedCount);
    return result.data.modifiedCount;
  } else {
    console.log('❌ Failed to mark all notifications as read:', result.error);
    return -1;
  }
}

async function testDeleteNotification(notificationId) {
  console.log(`\n🗑️ Testing Delete Notification: ${notificationId}...`);
  
  const result = await apiCall('DELETE', `/notifications/${notificationId}`);
  
  if (result.success) {
    console.log('✅ Notification deleted successfully');
    return true;
  } else {
    console.log('❌ Failed to delete notification:', result.error);
    return false;
  }
}

async function createTestNotifications() {
  console.log('\n🔄 Creating multiple test notifications...');
  
  const notifications = [
    {
      userId: testUsers.alice,
      type: 'match',
      relatedUserId: testUsers.bob,
      message: 'You have a new match with Bob Smith!'
    },
    {
      userId: testUsers.alice,
      type: 'like',
      relatedUserId: testUsers.charlie,
      message: 'Charlie Wilson liked your profile!'
    },
    {
      userId: testUsers.bob,
      type: 'match',
      relatedUserId: testUsers.alice,
      message: 'You have a new match with Alice Johnson!'
    }
  ];
  
  const createdIds = [];
  
  for (const notification of notifications) {
    const result = await apiCall('POST', '/notifications', notification);
    if (result.success) {
      createdIds.push(result.data.notification._id);
      console.log(`✅ Created notification for ${notification.userId}`);
    } else {
      console.log(`❌ Failed to create notification for ${notification.userId}:`, result.error);
    }
  }
  
  return createdIds;
}

// Main test runner
async function runAllTests() {
  console.log('� Starting Notification API Tests...');
  console.log('=====================================');
  
  try {
    // Test health check first
    const healthOk = await testHealthCheck();
    if (!healthOk) {
      console.log('❌ Server health check failed. Exiting tests.');
      return;
    }
    
    // Create multiple test notifications
    const notificationIds = await createTestNotifications();
    
    if (notificationIds.length === 0) {
      console.log('❌ No notifications created. Cannot continue tests.');
      return;
    }
    
    // Test getting notifications for Alice
    await testGetNotifications(testUsers.alice);
    
    // Test getting unread count
    await testGetUnreadCount(testUsers.alice);
    
    // Test marking one notification as read
    if (notificationIds.length > 0) {
      await testMarkAsRead(notificationIds[0]);
      
      // Check unread count again
      await testGetUnreadCount(testUsers.alice);
    }
    
    // Test getting notifications for Bob
    await testGetNotifications(testUsers.bob);
    
    // Test marking all notifications as read for Alice
    await testMarkAllAsRead(testUsers.alice);
    
    // Check Alice's notifications again
    await testGetNotifications(testUsers.alice);
    
    // Test deleting a notification
    if (notificationIds.length > 1) {
      await testDeleteNotification(notificationIds[1]);
      
      // Check notifications after deletion
      await testGetNotifications(testUsers.alice);
    }
    
    console.log('\n🎉 All notification tests completed!');
    console.log('=====================================');
    
  } catch (error) {
    console.error('❌ Test runner error:', error);
  }
}

// Run tests based on command line arguments
const args = process.argv.slice(2);

if (args.includes('--health-only')) {
  testHealthCheck();
} else {
  runAllTests();
}

// Export functions for use in other scripts
module.exports = {
  testHealthCheck,
  testCreateNotification,
  testGetNotifications,
  testGetUnreadCount,
  testMarkAsRead,
  testMarkAllAsRead,
  testDeleteNotification,
  createTestNotifications,
  runAllTests
};
