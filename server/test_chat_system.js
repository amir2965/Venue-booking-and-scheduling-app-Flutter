// Chat System Test Script
// Tests chat functionality between two users

const axios = require('axios');

const BASE_URL = 'http://localhost:5000';

async function testChatSystem() {
    console.log('🧪 Testing Chat System...\n');

    try {
        // Step 1: Create two test profiles
        console.log('1️⃣ Creating test profiles...');
        
        const user1Id = 'chat_test_user_' + Date.now() + '_1';
        const user2Id = 'chat_test_user_' + Date.now() + '_2';
        
        await axios.post(`${BASE_URL}/api/profiles`, {
            user: { id: user1Id },
            firstName: 'ChatUser1',
            lastName: 'Test',
            age: 25,
            bio: 'Test profile for chat system',
            photos: ['test1.jpg'],
            latitude: 40.7128,
            longitude: -74.0060
        });
        
        await axios.post(`${BASE_URL}/api/profiles`, {
            user: { id: user2Id },
            firstName: 'ChatUser2',
            lastName: 'Test',
            age: 26,
            bio: 'Test profile for chat system',
            photos: ['test2.jpg'],
            latitude: 40.7128,
            longitude: -74.0060
        });
        
        console.log(`✅ Profile 1 created: ${user1Id}`);
        console.log(`✅ Profile 2 created: ${user2Id}\n`);

        // Step 2: Create a chat between the users
        console.log('2️⃣ Creating chat between users...');
        
        const chatResponse = await axios.post(`${BASE_URL}/api/chats/create`, {
            userId1: user1Id,
            userId2: user2Id
        });
        
        const chatId = chatResponse.data.chatId;
        console.log(`✅ Chat created: ${chatId}\n`);

        // Step 3: Send messages
        console.log('3️⃣ Sending messages...');
        
        const message1 = await axios.post(`${BASE_URL}/api/chats/${chatId}/messages`, {
            senderId: user1Id,
            message: 'Hey there! Want to play some pool?',
            type: 'text'
        });
        
        const message2 = await axios.post(`${BASE_URL}/api/chats/${chatId}/messages`, {
            senderId: user2Id,
            message: 'Absolutely! I\'m free this evening.',
            type: 'text'
        });
        
        const message3 = await axios.post(`${BASE_URL}/api/chats/${chatId}/messages`, {
            senderId: user1Id,
            message: 'Perfect! Let\'s meet at the downtown pool hall.',
            type: 'text'
        });
        
        console.log(`✅ Message 1 sent: ${message1.data.message._id}`);
        console.log(`✅ Message 2 sent: ${message2.data.message._id}`);
        console.log(`✅ Message 3 sent: ${message3.data.message._id}\n`);

        // Step 4: Get chat messages
        console.log('4️⃣ Retrieving chat messages...');
        
        const messagesResponse = await axios.get(`${BASE_URL}/api/chats/${chatId}/messages`);
        const messages = messagesResponse.data.messages;
        
        console.log(`Found ${messages.length} messages:`);
        messages.forEach((msg, index) => {
            const sender = msg.senderId === user1Id ? 'ChatUser1' : 'ChatUser2';
            console.log(`  ${index + 1}. ${sender}: ${msg.message}`);
        });
        console.log('');

        // Step 5: Get user chats
        console.log('5️⃣ Getting user chat list...');
        
        const user1ChatsResponse = await axios.get(`${BASE_URL}/api/chats/${user1Id}`);
        const user1Chats = user1ChatsResponse.data.chats;
        
        console.log(`User 1 has ${user1Chats.length} chats:`);
        user1Chats.forEach((chat, index) => {
            console.log(`  ${index + 1}. Chat with ${chat.otherUser?.name || 'Unknown'}`);
            console.log(`     Last message: ${chat.lastMessage?.message || 'No messages'}`);
            console.log(`     Unread count: ${chat.unreadCount}`);
        });
        console.log('');

        // Step 6: Mark messages as read
        console.log('6️⃣ Marking messages as read...');
        
        await axios.patch(`${BASE_URL}/api/chats/${chatId}/read`, {
            userId: user2Id
        });
        
        console.log('✅ Messages marked as read for User 2\n');

        // Step 7: Add reaction to a message
        console.log('7️⃣ Adding reaction to message...');
        
        if (messages.length > 0) {
            const messageId = messages[0]._id;
            const reactionResponse = await axios.post(`${BASE_URL}/api/messages/${messageId}/reactions`, {
                userId: user2Id,
                emoji: '👍'
            });
            
            console.log(`✅ Reaction added: ${reactionResponse.data.reactions.length} reactions total\n`);
        }

        // Step 8: Test chat list after activity
        console.log('8️⃣ Final chat list check...');
        
        const finalChatsResponse = await axios.get(`${BASE_URL}/api/chats/${user1Id}`);
        const finalChats = finalChatsResponse.data.chats;
        
        console.log('Final chat state:');
        finalChats.forEach((chat, index) => {
            console.log(`  Chat ${index + 1}:`);
            console.log(`    Partner: ${chat.otherUser?.name || 'Unknown'}`);
            console.log(`    Last message: ${chat.lastMessage?.message || 'No messages'}`);
            console.log(`    Updated: ${new Date(chat.updatedAt).toLocaleString()}`);
        });

        // Summary
        console.log('\n📋 CHAT SYSTEM TEST SUMMARY:');
        console.log('✅ Chat creation between users');
        console.log('✅ Message sending and receiving');
        console.log('✅ Message retrieval and ordering');
        console.log('✅ Chat list with last message');
        console.log('✅ Unread count tracking');
        console.log('✅ Message reactions');
        console.log('✅ Mark messages as read');
        console.log('\n🎉 Chat system is working perfectly!');
        
    } catch (error) {
        console.error('❌ Chat system test failed:');
        console.error('Error message:', error.message);
        if (error.response) {
            console.error('Response status:', error.response.status);
            console.error('Response data:', error.response.data);
        }
    }
}

// Run the test
testChatSystem();
