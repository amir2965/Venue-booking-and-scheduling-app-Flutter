const { MongoClient } = require('mongodb');

async function checkAllProfiles() {
  const client = new MongoClient('mongodb://localhost:27017');
  
  try {
    await client.connect();
    console.log('Connected to MongoDB');
    
    const db = client.db('billiards_hub');
    
    // Get ALL profiles in the database
    const allProfiles = await db.collection('profiles').find({}).toArray();
    console.log(`\n=== TOTAL PROFILES IN DATABASE: ${allProfiles.length} ===\n`);
    
    allProfiles.forEach((p, i) => {
      console.log(`Profile ${i + 1}:`);
      console.log(`  userId: ${p.userId}`);
      console.log(`  firstName: ${p.profile?.firstName || 'N/A'}`);
      console.log(`  lastName: ${p.profile?.lastName || 'N/A'}`);
      console.log(`  displayName: ${p.profile?.user?.displayName || 'N/A'}`);
      console.log(`  username: ${p.profile?.username || 'N/A'}`);
      console.log(`  email: ${p.profile?.email || 'N/A'}`);
      console.log(`  _id: ${p._id}`);
      console.log('---');
    });
    
    // Check specifically for the Cat Camerani user
    console.log('\n=== SEARCHING FOR CAT CAMERANI ===');
    const catProfile = await db.collection('profiles').findOne({ 
      userId: 'JlNpNh4f4UePuAvhKnm5p0oTtFC3' 
    });
    if (catProfile) {
      console.log('Found Cat Camerani profile:');
      console.log(JSON.stringify(catProfile, null, 2));
    } else {
      console.log('Cat Camerani profile NOT FOUND');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }
}

checkAllProfiles();
