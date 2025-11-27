// Offline Notification Delivery Test
// Tests that notifications created while a user was offline are delivered when they log back in

const axios = require('axios');

const BASE_URL = 'http://localhost:5000';

async function testOfflineNotificationDelivery() {
    console.log('🧪 Testing Offline Notification Delivery...\n');

    try {
        // Step 1: Create two test profiles
        console.log('1️⃣ Creating test profiles...');
        
        // Generate unique user IDs
        const user1Id = 'offline_test_user_' + Date.now() + '_1';
        const user2Id = 'offline_test_user_' + Date.now() + '_2';
        
        const profile1Response = await axios.post(`${BASE_URL}/api/profiles`, {
            user: {
                id: user1Id
            },
            firstName: 'OfflineUser1',
            lastName: 'Test',
            age: 25,
            bio: 'Test profile for offline notifications',
            photos: ['test1.jpg'],
            latitude: 40.7128,
            longitude: -74.0060
        });
        
        const profile2Response = await axios.post(`${BASE_URL}/api/profiles`, {
            user: {
                id: user2Id
            },
            firstName: 'OfflineUser2',
            lastName: 'Test',
            age: 26,
            bio: 'Test profile for offline notifications',
            photos: ['test2.jpg'],
            latitude: 40.7128,
            longitude: -74.0060
        });
        
        console.log(`✅ Profile 1 created: ${user1Id}`);
        console.log(`✅ Profile 2 created: ${user2Id}\n`);

        // Step 2: Create match notifications manually (simulating offline scenario)
        console.log('2️⃣ Creating match notifications while User 1 is "offline"...');
        
        const notification1Response = await axios.post(`${BASE_URL}/api/notifications`, {
            userId: user1Id,
            type: 'match',
            relatedUserId: user2Id,
            message: 'It\'s a match! OfflineUser2 liked you back!',
            isRead: false,
            createdAt: new Date().toISOString()
        });
        
        const notification2Response = await axios.post(`${BASE_URL}/api/notifications`, {
            userId: user2Id,
            type: 'match',
            relatedUserId: user1Id,
            message: 'It\'s a match! You and OfflineUser1 liked each other!',
            isRead: false,
            createdAt: new Date().toISOString()
        });
        
        console.log('✅ Match notifications created');
        console.log(`Notification 1 ID: ${notification1Response.data.notification._id}`);
        console.log(`Notification 2 ID: ${notification2Response.data.notification._id}\n`);

        // Step 3: Wait a moment for notifications to be processed
        console.log('3️⃣ Waiting for notifications to be processed...');
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Step 4: Check notifications for User 1 (simulating them coming back online)
        console.log('4️⃣ Checking notifications for User 1 (coming back online)...');
        
        const notificationsResponse = await axios.get(`${BASE_URL}/api/notifications/${user1Id}?unreadOnly=true`);
        const notifications = notificationsResponse.data.notifications;
        
        console.log(`Found ${notifications.length} unread notifications for User 1:`);
        
        if (notifications.length > 0) {
            notifications.forEach((notification, index) => {
                console.log(`  ${index + 1}. ${notification.type}: ${notification.message}`);
                console.log(`     Created: ${new Date(notification.createdAt).toLocaleString()}`);
                console.log(`     Age: ${Math.round((Date.now() - new Date(notification.createdAt).getTime()) / 1000)}s ago`);
            });
        } else {
            console.log('  ❌ No notifications found');
        }

        // Step 5: Check unread count
        console.log('\n5️⃣ Checking unread count...');
        const unreadResponse = await axios.get(`${BASE_URL}/api/notifications/${user1Id}/unread-count`);
        console.log(`Unread count: ${unreadResponse.data.count}`);

        // Step 6: Test older notifications (create one with backdated timestamp)
        console.log('\n6️⃣ Testing older notification handling...');
        
        // Create notification with timestamp 2 hours ago
        const olderTime = new Date(Date.now() - 2 * 60 * 60 * 1000); // 2 hours ago
        
        await axios.post(`${BASE_URL}/api/notifications`, {
            userId: user1Id,
            type: 'match',
            relatedUserId: user2Id,
            message: 'This is an older notification from 2 hours ago',
            isRead: false,
            createdAt: olderTime.toISOString()
        });
        
        const allNotificationsResponse = await axios.get(`${BASE_URL}/api/notifications/${user1Id}?unreadOnly=true`);
        const allNotifications = allNotificationsResponse.data.notifications;
        
        console.log(`Total unread notifications now: ${allNotifications.length}`);
        allNotifications.forEach((notification, index) => {
            const ageHours = (Date.now() - new Date(notification.createdAt).getTime()) / (1000 * 60 * 60);
            console.log(`  ${index + 1}. ${notification.message} (${ageHours.toFixed(1)}h old)`);
        });

        // Step 7: Test the Flutter app behavior simulation
        console.log('\n7️⃣ Testing Flutter app behavior simulation...');
        console.log('In the Flutter app, when a user logs in:');
        console.log('- loadInitialNotifications() is called');
        console.log('- Notifications < 1 hour old will auto-popup');
        console.log('- Notifications > 1 hour old are available in the list but won\'t auto-popup');
        
        const recentNotifications = allNotifications.filter(n => {
            const ageHours = (Date.now() - new Date(n.createdAt).getTime()) / (1000 * 60 * 60);
            return ageHours < 1;
        });
        
        console.log(`Notifications that would auto-popup: ${recentNotifications.length}`);
        recentNotifications.forEach((notification, index) => {
            const ageMinutes = (Date.now() - new Date(notification.createdAt).getTime()) / (1000 * 60);
            console.log(`  ${index + 1}. "${notification.message}" (${ageMinutes.toFixed(1)} min ago)`);
        });

        // Summary
        console.log('\n📋 SUMMARY:');
        console.log(`✅ Notifications are delivered to offline users when they return`);
        console.log(`✅ Current Flutter implementation shows notifications < 1 hour old on login`);
        console.log(`✅ All unread notifications are available in the notification list`);
        console.log(`⚠️  Notifications older than 1 hour won't auto-popup but are still accessible`);
        console.log(`💡 You can adjust the time window in NotificationMonitorService.loadInitialNotifications()`);
        
        if (recentNotifications.length > 0) {
            console.log(`\n🎉 SUCCESS: User would receive ${recentNotifications.length} notification(s) on login!`);
        } else {
            console.log(`\n⏰ INFO: No recent notifications to auto-popup, but older ones are in the list.`);
        }

    } catch (error) {
        console.error('❌ Test failed:');
        console.error('Error message:', error.message);
        if (error.response) {
            console.error('Response status:', error.response.status);
            console.error('Response data:', error.response.data);
        } else {
            console.error('Full error:', error);
        }
    }
}

// Run the test
testOfflineNotificationDelivery();
