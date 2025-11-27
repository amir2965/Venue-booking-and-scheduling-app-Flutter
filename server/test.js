// Test MongoDB Connection
const mongoose = require('mongoose');

const MONGODB_USERNAME = 'amirmahdi82sf';
const MONGODB_PASSWORD = 'nmBGXaUUTiSOYwL6';
const MONGODB_CLUSTER = 'cluster0.lpgew0e.mongodb.net';
const DB_NAME = 'billiards_hub';

const uri = `mongodb+srv://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@${MONGODB_CLUSTER}/${DB_NAME}?retryWrites=true&w=majority`;

async function testConnection() {
    try {
        await mongoose.connect(uri, {
            serverSelectionTimeoutMS: 5000,
            socketTimeoutMS: 45000
        });
        console.log('Successfully connected to MongoDB Atlas!');

        // Create a test profile
        const profileSchema = new mongoose.Schema({
            userId: { type: String, required: true, unique: true },
            profile: { type: Object, required: true }
        });

        const Profile = mongoose.model('Profile', profileSchema);

        const testProfile = new Profile({
            userId: 'test-user-' + Date.now(),
            profile: {
                user: {
                    id: 'test-user-' + Date.now(),
                    email: 'test@example.com',
                    displayName: 'Test User'
                },
                firstName: 'Test',
                bio: 'Test Bio',
                skillLevel: 1.0,
                skillTier: 'Beginner',
                preferredGameTypes: ['8-Ball'],
                preferredLocation: 'Test Location',
                availability: { 'Monday': ['Evening'] },
                experiencePoints: 0,
                matchesPlayed: 0,
                winRate: 0,
                achievements: []
            }
        });

        await testProfile.save();
        console.log('Test profile created successfully!');

        // Retrieve the test profile
        const savedProfile = await Profile.findOne({ userId: testProfile.userId });
        console.log('Retrieved profile:', savedProfile);

        await mongoose.disconnect();
        console.log('Disconnected from MongoDB Atlas');
    } catch (error) {
        console.error('Error:', error);
    }
}

testConnection();
