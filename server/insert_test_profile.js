const { MongoClient } = require('mongodb');

async function insertTestProfile() {
  const client = new MongoClient('mongodb://localhost:27017');
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db('billiards_hub');
    
    // Create the Cat Camerani profile exactly as you showed
    const catProfile = {
      userId: 'JlNpNh4f4UePuAvhKnm5p0oTtFC3',
      profile: {
        user: {
          id: 'JlNpNh4f4UePuAvhKnm5p0oTtFC3',
          email: 'amir2965dffff@yahoo.com',
          displayName: 'Cat Camerani',
          photoUrl: null,
          emailVerified: false,
          createdAt: '2025-07-16T08:08:27.000Z'
        },
        firstName: 'Cat',
        lastName: 'Camerani',
        username: 'cat123',
        bio: 'Looking forward to connecting with fellow billiards enthusiasts!',
        skillLevel: 2,
        skillTier: 'Intermediate',
        preferredGameTypes: ['Competitive'],
        preferredSports: ['Table Tennis', 'Mini Golf'],
        preferredLocation: 'Brisbane',
        profileImageUrl: null,
        profileImageUrls: null,
        experiencePoints: 10,
        matchesPlayed: 0,
        winRate: 0,
        achievements: [],
        dateOfBirth: '2000-07-21T00:00:00.000Z',
        email: 'amir2965dffff@yahoo.com',
        userId: 'JlNpNh4f4UePuAvhKnm5p0oTtFC3'
      },
      __v: 0
    };
    
    // Check if profile already exists
    const existing = await db.collection('profiles').findOne({ 
      userId: catProfile.userId 
    });
    
    if (existing) {
      console.log('⚠️  Profile already exists for this userId');
      console.log('   Deleting old profile first...');
      await db.collection('profiles').deleteOne({ userId: catProfile.userId });
      console.log('   ✅ Old profile deleted');
    }
    
    // Insert the profile
    const result = await db.collection('profiles').insertOne(catProfile);
    console.log('\n✅ PROFILE INSERTED SUCCESSFULLY!');
    console.log(`   _id: ${result.insertedId}`);
    console.log(`   userId: ${catProfile.userId}`);
    console.log(`   firstName: ${catProfile.profile.firstName}`);
    console.log(`   lastName: ${catProfile.profile.lastName}`);
    console.log(`   displayName: ${catProfile.profile.user.displayName}`);
    console.log(`   username: ${catProfile.profile.username}`);
    console.log(`   email: ${catProfile.profile.email}`);
    
    // Verify by reading it back
    console.log('\n🔍 VERIFYING: Reading profile back from database...');
    const verified = await db.collection('profiles').findOne({ 
      userId: catProfile.userId 
    });
    
    if (verified) {
      console.log('✅ VERIFICATION SUCCESS!');
      console.log(`   Database has: ${verified.profile.firstName} ${verified.profile.lastName}`);
      console.log(`   Username: ${verified.profile.username}`);
    } else {
      console.log('❌ VERIFICATION FAILED - Could not read profile back');
    }
    
    // Test the API endpoint
    console.log('\n🌐 TESTING API ENDPOINT...');
    console.log(`   Run this command to test:`);
    console.log(`   curl http://localhost:5000/api/profile/${catProfile.userId}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

insertTestProfile();
