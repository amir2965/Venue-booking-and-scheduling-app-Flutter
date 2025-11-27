// MongoDB API Server (server.js)
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json({
  limit: '50mb',
  verify: (req, res, buf) => {
    // Only validate JSON if there's actually content to parse
    if (buf && buf.length > 0) {
      try {
        JSON.parse(buf);
      } catch(e) {
        console.error('Invalid JSON received:', buf.toString());
        res.status(400).json({ error: 'Invalid JSON' });
        throw new Error('Invalid JSON');
      }
    }
  }
}));

// Connect to MongoDB
// Load environment variables
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/billiards_hub';

// If using Atlas, construct URI from environment variables
const MONGODB_USERNAME = process.env.MONGODB_USERNAME;
const MONGODB_PASSWORD = process.env.MONGODB_PASSWORD;
const MONGODB_CLUSTER = process.env.MONGODB_CLUSTER;
const DB_NAME = process.env.DB_NAME || 'billiards_hub';

let uri = MONGODB_URI;

// If Atlas credentials are provided, use them instead
if (MONGODB_USERNAME && MONGODB_PASSWORD && MONGODB_CLUSTER) {
  uri = `mongodb+srv://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@${MONGODB_CLUSTER}/${DB_NAME}?retryWrites=true&w=majority`;
}

console.log('Connecting to MongoDB...');
console.log('URI:', uri.replace(/:[^:@]+@/, ':****@')); // Hide password in logs

// Configure connection options - use Stable API for Atlas
const isAtlas = uri.includes('mongodb+srv://');
const connectionOptions = {
  serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
  socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
};

// Add Stable API version for MongoDB Atlas
if (isAtlas) {
  connectionOptions.serverApi = {
    version: '1',
    strict: true,
    deprecationErrors: true,
  };
  console.log('📡 Using MongoDB Atlas with Stable API v1');
} else {
  console.log('💻 Using local MongoDB');
}

mongoose.connect(uri, connectionOptions).then(() => {
  console.log('✓ Connected to MongoDB successfully');
  console.log(`📊 Database: ${DB_NAME}`);
}).catch(err => {
  console.error('✗ MongoDB connection error:', err.message);
  console.error('\n⚠️  Please ensure MongoDB is running or check your connection settings');
  if (isAtlas) {
    console.error('   For MongoDB Atlas:');
    console.error('   - Check your username and password in .env file');
    console.error('   - Whitelist your IP address in Atlas Network Access');
    console.error('   - Verify the cluster URL is correct\n');
  } else {
    console.error('   For local MongoDB: Install MongoDB from https://www.mongodb.com/try/download/community\n');
  }
});

// Player Profile Schema
const profileSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  profile: { type: Object, required: true }
});

const Profile = mongoose.model('Profile', profileSchema);

// Likes Schema
const likeSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  likedProfileId: { type: String, required: true },
  isMatch: { type: Boolean, default: false }
});

const Like = mongoose.model('Like', likeSchema);

// Notification Schema for match alerts
const notificationSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  type: { type: String, required: true }, // 'match', 'like', etc.
  relatedUserId: { type: String, required: true },
  message: { type: String, required: true },
  isRead: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const Notification = mongoose.model('Notification', notificationSchema);

// Chat Schema for messaging between matched users
const chatSchema = new mongoose.Schema({
  participants: [{ type: String, required: true }], // Array of user IDs
  lastMessage: {
    senderId: String,
    message: String,
    timestamp: Date,
    type: { type: String, default: 'text' } // 'text', 'image', 'emoji'
  },
  unreadCounts: {
    type: Map,
    of: Number,
    default: new Map()
  },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const Chat = mongoose.model('Chat', chatSchema);

// Message Schema for individual messages
const messageSchema = new mongoose.Schema({
  chatId: { type: String, required: true },
  senderId: { type: String, required: true },
  message: { type: String, required: true },
  type: { type: String, default: 'text' }, // 'text', 'image', 'emoji'
  timestamp: { type: Date, default: Date.now },
  isRead: { type: Boolean, default: false },
  reactions: [{
    userId: String,
    emoji: String,
    timestamp: { type: Date, default: Date.now }
  }]
});

const Message = mongoose.model('Message', messageSchema);

// User Status Schema for tracking online presence
const userStatusSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  isOnline: { type: Boolean, default: false },
  lastSeen: { type: Date, default: Date.now },
  deviceInfo: {
    platform: String,
    version: String,
    userAgent: String
  },
  updatedAt: { type: Date, default: Date.now }
});

const UserStatus = mongoose.model('UserStatus', userStatusSchema);

// Wishlist Schema for saving venues
const wishlistSchema = new mongoose.Schema({
  name: { type: String, required: true, maxLength: 50 },
  userId: { type: String, required: true },
  venueIds: [{ type: String, required: true }],
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const Wishlist = mongoose.model('Wishlist', wishlistSchema);

// Create indexes for efficient chat queries with error handling
async function createIndexes() {
  try {
    await Chat.collection.createIndex({ participants: 1 });
    await Chat.collection.createIndex({ updatedAt: -1 });
    await Message.collection.createIndex({ chatId: 1, timestamp: -1 });
    await Message.collection.createIndex({ senderId: 1, timestamp: -1 });
    
    // Check if UserStatus index exists and drop if needed
    try {
      const indexes = await UserStatus.collection.indexes();
      const hasConflict = indexes.some(idx => 
        idx.name === 'userId_1' && idx.unique !== true
      );
      if (hasConflict) {
        await UserStatus.collection.dropIndex('userId_1');
      }
    } catch (err) {
      // Index doesn't exist yet, that's fine
    }
    
    await UserStatus.collection.createIndex({ userId: 1 }, { unique: true });
    await UserStatus.collection.createIndex({ isOnline: 1 });
    
    console.log('✓ Database indexes created successfully');
  } catch (error) {
    // Ignore index conflicts - indexes already exist
    if (error.code !== 86 && error.codeName !== 'IndexKeySpecsConflict') {
      console.error('⚠️  Index creation warning:', error.message);
    }
  }
}

// Create indexes after connection
mongoose.connection.once('open', () => {
  createIndexes();
});

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    await mongoose.connection.db.admin().ping();
    const dbState = mongoose.connection.readyState;
    const isConnected = dbState === 1;
    
    res.status(200).json({ 
      status: 'ok', 
      message: 'Server is healthy',
      dbConnected: isConnected,
      dbState: dbState // 0 = disconnected, 1 = connected, 2 = connecting, 3 = disconnecting
    });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(500).json({ 
      status: 'error', 
      message: error.message,
      dbConnected: false 
    });
  }
});

// Test endpoint to create a mock profile for testing
app.post('/api/test/create-mock-profile', async (req, res) => {
  try {
    const mockProfile = {
      user: {
        id: "test-user-123",
        email: "test@example.com",
        displayName: "Test User",
        photoUrl: null,
        emailVerified: true,
        createdAt: new Date().toISOString()
      },
      firstName: "Test",
      lastName: "User",
      username: "testuser123",
      bio: "This is a test profile created by the server.",
      skillLevel: 2.5,
      skillTier: "Intermediate",
      preferredGameTypes: ["8-Ball", "9-Ball"],
      preferredLocation: "Test City",
      profileImageUrl: null,
      availability: {
        "Monday": ["Evening"],
        "Wednesday": ["Afternoon", "Evening"]
      },
      experiencePoints: 50,
      matchesPlayed: 5,
      winRate: 0.6,
      achievements: ["First Win", "5 Games Played"]
    };

    // Check if test profile already exists
    const existingProfile = await Profile.findOne({ userId: mockProfile.user.id });
    if (existingProfile) {
      return res.status(200).json({ 
        success: true, 
        message: 'Mock profile already exists',
        data: existingProfile.profile 
      });
    }

    const newProfile = new Profile({
      userId: mockProfile.user.id,
      profile: mockProfile
    });
    
    await newProfile.save();
    console.log('Mock profile created successfully for testing');
    
    res.status(201).json({ 
      success: true, 
      message: 'Mock profile created successfully',
      data: newProfile.profile 
    });
  } catch (error) {
    console.error('Error creating mock profile:', error);
    res.status(500).json({ error: error.message });
  }
});

// Test endpoint to create multiple mock profiles for matchmaking testing
app.post('/api/test/create-multiple-profiles', async (req, res) => {
  try {
    const testProfiles = [
      {
        user: {
          id: "alice-test-456",
          email: "alice@example.com",
          displayName: "Alice Johnson",
          photoUrl: null,
          emailVerified: true,
          createdAt: new Date().toISOString()
        },
        firstName: "Alice",
        lastName: "Johnson",
        username: "alice_pool_pro",
        bio: "Advanced player looking for challenging matches",
        skillLevel: 4.2,
        skillTier: "Advanced",
        preferredGameTypes: ["Billiards", "Snooker"],
        preferredLocation: "Brisbane",
        profileImageUrl: null,
        availability: {
          "Tuesday": ["Evening"],
          "Thursday": ["Afternoon", "Evening"],
          "Saturday": ["Morning", "Afternoon"]
        },
        experiencePoints: 420,
        matchesPlayed: 35,
        winRate: 0.75,
        achievements: ["Tournament Winner", "50 Games Played", "High Roller"]
      },
      {
        user: {
          id: "bob-test-789",
          email: "bob@example.com",
          displayName: "Bob Smith",
          photoUrl: null,
          emailVerified: true,
          createdAt: new Date().toISOString()
        },
        firstName: "Bob",
        lastName: "Smith",
        username: "bobthe8ball",
        bio: "Casual player, love the game and meeting new people",
        skillLevel: 1.8,
        skillTier: "Beginner",
        preferredGameTypes: ["Bowling"],
        preferredLocation: "Brisbane",
        profileImageUrl: null,
        availability: {
          "Monday": ["Evening"],
          "Wednesday": ["Evening"],
          "Friday": ["Evening"]
        },
        experiencePoints: 90,
        matchesPlayed: 12,
        winRate: 0.42,
        achievements: ["First Win", "10 Games Played"]
      },
      {
        user: {
          id: "charlie-test-101",
          email: "charlie@example.com",
          displayName: "Charlie Wilson",
          photoUrl: null,
          emailVerified: true,
          createdAt: new Date().toISOString()
        },
        firstName: "Charlie",
        lastName: "Wilson",
        username: "charlie_cue_master",
        bio: "Intermediate player working my way up!",
        skillLevel: 3.1,
        skillTier: "Intermediate",
        preferredGameTypes: ["Billiards", "Darts"],
        preferredLocation: "Brisbane",
        profileImageUrl: null,
        availability: {
          "Monday": ["Afternoon"],
          "Wednesday": ["Afternoon", "Evening"],
          "Saturday": ["Afternoon"]
        },
        experiencePoints: 155,
        matchesPlayed: 28,
        winRate: 0.57,
        achievements: ["First Win", "25 Games Played", "Improvement"]
      },
      {
        user: {
          id: "diana-test-202",
          email: "diana@example.com",
          displayName: "Diana Lee",
          photoUrl: null,
          emailVerified: true,
          createdAt: new Date().toISOString()
        },
        firstName: "Diana",
        lastName: "Lee",
        username: "diana_snooker_queen",
        bio: "Professional player with years of experience",
        skillLevel: 4.8,
        skillTier: "Expert",
        preferredGameTypes: ["Table Tennis", "Mini Golf", "Snooker"],
        preferredLocation: "Brisbane",
        profileImageUrl: null,
        availability: {
          "Tuesday": ["Morning", "Afternoon"],
          "Thursday": ["Morning", "Afternoon"],
          "Sunday": ["Morning", "Afternoon", "Evening"]
        },
        experiencePoints: 780,
        matchesPlayed: 85,
        winRate: 0.86,
        achievements: ["Tournament Winner", "100 Games Played", "Champion", "Perfect Week"]
      }
    ];

    const createdProfiles = [];
    
    for (const mockProfile of testProfiles) {
      // Check if profile already exists
      const existingProfile = await Profile.findOne({ userId: mockProfile.user.id });
      if (!existingProfile) {
        const newProfile = new Profile({
          userId: mockProfile.user.id,
          profile: mockProfile
        });
        await newProfile.save();
        createdProfiles.push(mockProfile);
        console.log(`Mock profile created for ${mockProfile.username}`);
      }
    }
    
    res.status(201).json({ 
      success: true, 
      message: `Created ${createdProfiles.length} new mock profiles`,
      created: createdProfiles.length,
      data: createdProfiles 
    });
  } catch (error) {
    console.error('Error creating multiple mock profiles:', error);
    res.status(500).json({ error: error.message });
  }
});

// Routes
// Get all profiles
app.get('/api/profiles', async (req, res) => {
  try {
    const profiles = await Profile.find();
    res.status(200).json(profiles.map(p => p.profile));
  } catch (error) {
    console.error('Error getting profiles:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get profile by ID (both singular and plural routes for compatibility)
app.get('/api/profile/:id', async (req, res) => {
  try {
    console.log('Getting profile for user:', req.params.id);
    const profile = await Profile.findOne({ userId: req.params.id });
    if (!profile) {
      console.log('Profile not found for user:', req.params.id);
      return res.status(404).json({ error: 'Profile not found' });
    }
    console.log('Profile found for user:', req.params.id);
    res.status(200).json({ success: true, data: profile.profile });
  } catch (error) {
    console.error('Error getting profile by ID:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/profiles/:id', async (req, res) => {
  try {
    console.log('Getting profile for user:', req.params.id);
    const profile = await Profile.findOne({ userId: req.params.id });
    if (!profile) {
      console.log('Profile not found for user:', req.params.id);
      return res.status(404).json({ success: false, error: 'Profile not found' });
    }
    console.log('Profile found for user:', req.params.id);
    res.status(200).json({ success: true, data: profile.profile });
  } catch (error) {
    console.error('Error getting profile by ID:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create/Update profile (PUT method for upsert - both singular and plural routes)
app.put('/api/profile/:id', async (req, res) => {
  try {
    console.log('Received profile create/update request for user:', req.params.id);
    console.log('Profile data:', JSON.stringify(req.body, null, 2));
    
    const userId = req.params.id;
    const profileData = req.body;
    
    // Validate required fields
    if (!profileData.user || !profileData.user.id) {
      return res.status(400).json({ error: 'Missing required field: user.id' });
    }

    // Try to find existing profile
    let profile = await Profile.findOne({ userId });
    
    if (profile) {
      // Update existing profile
      console.log('Updating existing profile for user:', userId);
      profile.profile = profileData;
      await profile.save();
      console.log('Profile updated successfully for user:', userId);
      res.status(200).json({ success: true, data: profile.profile });
    } else {
      // Create new profile
      console.log('Creating new profile for user:', userId);
      const newProfile = new Profile({
        userId,
        profile: profileData
      });
      
      await newProfile.save();
      console.log('New profile created successfully for user:', userId);
      res.status(201).json({ success: true, data: newProfile.profile });
    }
  } catch (error) {
    console.error('Error creating/updating profile:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create profile (POST method)
app.post('/api/profiles', async (req, res) => {
  try {
    console.log('Received profile creation request:', JSON.stringify(req.body, null, 2));
    const profileData = req.body;
    
    // Validate required fields
    if (!profileData.user || !profileData.user.id) {
      return res.status(400).json({ error: 'Missing required field: user.id' });
    }

    const userId = profileData.user.id;
    
    // Check if profile already exists
    const existingProfile = await Profile.findOne({ userId });
    if (existingProfile) {
      return res.status(409).json({ error: 'Profile already exists' });
    }
    
    const newProfile = new Profile({
      userId,
      profile: profileData
    });
    
    await newProfile.save();
    console.log('New profile created for user:', userId);
    res.status(201).json(newProfile.profile);
  } catch (error) {
    console.error('Error creating profile:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update profile (PUT method for existing profiles)
app.put('/api/profiles/:id', async (req, res) => {
  try {
    const profile = await Profile.findOne({ userId: req.params.id });
    if (!profile) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    
    profile.profile = req.body;
    await profile.save();
    console.log('Profile updated for user:', req.params.id);
    
    res.status(200).json(profile.profile);
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add like
app.post('/api/likes', async (req, res) => {
  try {
    const { userId, likedProfileId, isMatch } = req.body;
    
    const newLike = new Like({
      userId,
      likedProfileId,
      isMatch
    });
    
    await newLike.save();
    console.log(`User ${userId} liked profile ${likedProfileId}. Match: ${isMatch}`);
    res.status(201).json(newLike);
  } catch (error) {
    console.error('Error creating like:', error);
    res.status(500).json({ error: error.message });
  }
});

// Intelligent Matchmaking Endpoints

// Get potential matches for a user
app.get('/api/matchmaking/:userId/potential-matches', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 10, excludeViewed = true } = req.query;
    
    console.log(`🔍 [${new Date().toISOString()}] Finding potential matches for user: ${userId}`);
    console.log(`📋 Parameters: limit=${limit}, excludeViewed=${excludeViewed}`);
    
    // Get the current user's profile
    const currentUserProfile = await Profile.findOne({ userId });
    if (!currentUserProfile) {
      console.log(`❌ User profile not found for userId: ${userId}`);
      return res.status(404).json({ 
        success: false,
        error: 'User profile not found',
        userId: userId
      });
    }
    
    const userProfile = currentUserProfile.profile;
    console.log(`✅ Found user profile: ${userProfile.firstName || 'Unknown'}`);
    
    // Get users that current user has already liked/passed
    const viewedUserIds = excludeViewed ? 
      (await Like.find({ userId }).distinct('likedProfileId')) : [];
    
    console.log(`👀 User has viewed ${viewedUserIds.length} profiles before`);
    
    // Build match query with intelligent filtering
    const matchQuery = {
      userId: { $ne: userId }, // Exclude self
      ...(excludeViewed && viewedUserIds.length > 0 ? 
        { userId: { $nin: [userId, ...viewedUserIds] } } : 
        { userId: { $ne: userId } })
    };
    
    console.log(`🎯 Match query:`, JSON.stringify(matchQuery));
    
    // Get potential matches
    let potentialMatches = await Profile.find(matchQuery);
    
    console.log(`📦 Found ${potentialMatches.length} total potential matches from database`);
    
    // If no matches found, provide detailed logging
    if (potentialMatches.length === 0) {
      const totalProfiles = await Profile.countDocuments({ userId: { $ne: userId } });
      console.log(`📊 Debug info: Total profiles in DB (excluding self): ${totalProfiles}`);
      console.log(`📊 Debug info: Viewed profiles count: ${viewedUserIds.length}`);
      
      if (totalProfiles === 0) {
        console.log(`⚠️  No other profiles exist in the database`);
      } else if (viewedUserIds.length >= totalProfiles) {
        console.log(`⚠️  User has viewed all available profiles`);
      }
    }
    
    // Calculate match scores and sort by compatibility
    const scoredMatches = potentialMatches
      .map(match => ({
        ...match.toObject(),
        matchScore: calculateMatchScore(userProfile, match.profile)
      }))
      .sort((a, b) => b.matchScore - a.matchScore)
      .slice(0, parseInt(limit));
    
    console.log(`✅ Returning ${scoredMatches.length} scored matches for user ${userId}`);
    
    res.status(200).json({
      success: true,
      matches: scoredMatches.map(match => match.profile),
      totalFound: scoredMatches.length,
      viewedCount: viewedUserIds.length,
      requestTime: new Date().toISOString()
    });
    
  } catch (error) {
    console.error(`❌ [${new Date().toISOString()}] Error finding potential matches for user ${req.params.userId}:`, error);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ 
      success: false,
      error: error.message,
      userId: req.params.userId,
      timestamp: new Date().toISOString()
    });
  }
});

// Record a like/pass action
app.post('/api/matchmaking/action', async (req, res) => {
  try {
    const { userId, targetUserId, action } = req.body; // action: 'like' or 'pass'
    
    if (!['like', 'pass'].includes(action)) {
      return res.status(400).json({ error: 'Invalid action. Must be "like" or "pass"' });
    }
    
    console.log(`User ${userId} ${action}d user ${targetUserId}`);
    
    // Check if target user has already liked this user
    const existingLike = await Like.findOne({ 
      userId: targetUserId, 
      likedProfileId: userId 
    });
    
    const isMatch = action === 'like' && existingLike !== null;
    
    // Record the action
    const newAction = new Like({
      userId,
      likedProfileId: targetUserId,
      isMatch: isMatch
    });
    
    await newAction.save();
    
    // If it's a match, update both records and create notifications
    if (isMatch) {
      await Like.updateOne(
        { userId: targetUserId, likedProfileId: userId },
        { isMatch: true }
      );
      
      // Get both user profiles for notification details
      const [currentUserProfile, targetUserProfile] = await Promise.all([
        Profile.findOne({ userId }),
        Profile.findOne({ userId: targetUserId })
      ]);
      
      if (currentUserProfile && targetUserProfile) {
        const firstName1 = currentUserProfile.profile.firstName || 'Someone';
        const firstName2 = targetUserProfile.profile.firstName || 'Someone';
        
        // Create notification for the first user (who liked first)
        const notificationForFirstUser = new Notification({
          userId: targetUserId,
          type: 'match',
          relatedUserId: userId,
          message: `It's a match! ${firstName1} liked you back!`
        });
        
        // Create notification for the second user (who just liked back)
        const notificationForSecondUser = new Notification({
          userId: userId,
          type: 'match',
          relatedUserId: targetUserId,
          message: `It's a match! You and ${firstName2} liked each other!`
        });
        
        await Promise.all([
          notificationForFirstUser.save(),
          notificationForSecondUser.save()
        ]);
        
        console.log(`📱 Match notifications created for ${firstName1} and ${firstName2}`);
      }
      
      console.log(`🎉 Match created between ${userId} and ${targetUserId}!`);
    }
    
    res.status(200).json({
      success: true,
      action,
      isMatch,
      message: isMatch ? 'It\'s a match! 🎉' : `${action} recorded successfully`
    });
    
  } catch (error) {
    console.error('Error recording matchmaking action:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get user's matches
app.get('/api/matchmaking/:userId/matches', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`Getting matches for user: ${userId}`);
    
    // Find all mutual likes (matches)
    const userLikes = await Like.find({ userId, isMatch: true });
    const matchedUserIds = userLikes.map(like => like.likedProfileId);
    
    // Get profiles of matched users
    const matchedProfiles = await Profile.find({ 
      userId: { $in: matchedUserIds } 
    });
    
    console.log(`Found ${matchedProfiles.length} matches for user ${userId}`);
    
    res.status(200).json({
      success: true,
      matches: matchedProfiles.map(profile => profile.profile),
      totalMatches: matchedProfiles.length
    });
    
  } catch (error) {
    console.error('Error getting user matches:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get matchmaking statistics
app.get('/api/matchmaking/:userId/stats', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const [totalLikes, totalMatches, totalPasses] = await Promise.all([
      Like.countDocuments({ userId }),
      Like.countDocuments({ userId, isMatch: true }),
      Like.countDocuments({ userId, isMatch: false })
    ]);
    
    const matchRate = totalLikes > 0 ? (totalMatches / totalLikes * 100).toFixed(1) : 0;
    
    res.status(200).json({
      success: true,
      stats: {
        totalLikes,
        totalMatches,
        totalPasses,
        matchRate: parseFloat(matchRate),
        totalActions: totalLikes + totalPasses
      }
    });
    
  } catch (error) {
    console.error('Error getting matchmaking stats:', error);
    res.status(500).json({ error: error.message });
  }
});

// Notification Endpoints

// Get user notifications
app.get('/api/notifications/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { unreadOnly = false, limit = 50 } = req.query;
    
    const query = { userId };
    if (unreadOnly === 'true') {
      query.isRead = false;
    }
    
    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));
    
    res.status(200).json({
      success: true,
      notifications,
      unreadCount: await Notification.countDocuments({ userId, isRead: false })
    });
    
  } catch (error) {
    console.error('Error getting notifications:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create a new notification
app.post('/api/notifications', async (req, res) => {
  try {
    const { userId, type, relatedUserId, message, isRead = false } = req.body;
    
    // Validate required fields
    if (!userId || !type || !relatedUserId || !message) {
      return res.status(400).json({ 
        error: 'Missing required fields: userId, type, relatedUserId, message' 
      });
    }
    
    const notification = new Notification({
      userId,
      type,
      relatedUserId,
      message,
      isRead,
      createdAt: new Date()
    });
    
    const savedNotification = await notification.save();
    
    res.status(201).json({
      success: true,
      notification: savedNotification
    });
    
  } catch (error) {
    console.error('Error creating notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get unread notification count (separate endpoint)
app.get('/api/notifications/:userId/unread-count', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const count = await Notification.countDocuments({ 
      userId, 
      isRead: false 
    });
    
    res.status(200).json({ count });
    
  } catch (error) {
    console.error('Error getting unread count:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete a notification
app.delete('/api/notifications/:notificationId', async (req, res) => {
  try {
    const { notificationId } = req.params;
    
    const result = await Notification.deleteOne({ _id: notificationId });
    
    if (result.deletedCount === 0) {
      return res.status(404).json({ 
        error: 'Notification not found' 
      });
    }
    
    res.status(200).json({ 
      success: true, 
      message: 'Notification deleted successfully' 
    });
    
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// Mark notification as read
app.patch('/api/notifications/:notificationId/read', async (req, res) => {
  try {
    const { notificationId } = req.params;
    
    const notification = await Notification.findByIdAndUpdate(
      notificationId,
      { isRead: true },
      { new: true }
    );
    
    if (!notification) {
      return res.status(404).json({ 
        error: 'Notification not found' 
      });
    }
    
    res.status(200).json({
      success: true,
      notification
    });
    
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: error.message });
  }
});

// Mark all notifications as read for a user
app.patch('/api/notifications/:userId/mark-all-read', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const result = await Notification.updateMany(
      { userId, isRead: false },
      { isRead: true }
    );
    
    res.status(200).json({
      success: true,
      message: `Marked ${result.modifiedCount} notifications as read`,
      modifiedCount: result.modifiedCount
    });
    
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ error: error.message });
  }
});

// Intelligent Match Score Calculation Function
function calculateMatchScore(userProfile, targetProfile) {
  let score = 0;
  let maxScore = 0;
  
  // Skill Level Compatibility (40% weight)
  const skillWeight = 40;
  const skillDiff = Math.abs(userProfile.skillLevel - targetProfile.skillLevel);
  const skillScore = Math.max(0, 100 - (skillDiff * 25)); // Penalty for skill gap
  score += skillScore * (skillWeight / 100);
  maxScore += skillWeight;
  
  // Location Proximity (25% weight)
  const locationWeight = 25;
  if (userProfile.preferredLocation === targetProfile.preferredLocation) {
    score += locationWeight;
  } else if (userProfile.preferredLocation && targetProfile.preferredLocation) {
    // Same city gets partial points (you could enhance this with geo-distance)
    score += locationWeight * 0.3;
  }
  maxScore += locationWeight;
  
  // Game Type Compatibility (20% weight)
  const gameTypeWeight = 20;
  const userGameTypes = userProfile.preferredGameTypes || [];
  const targetGameTypes = targetProfile.preferredGameTypes || [];
  const commonGameTypes = userGameTypes.filter(type => 
    targetGameTypes.includes(type)
  );
  if (commonGameTypes.length > 0) {
    const gameTypeScore = (commonGameTypes.length / Math.max(userGameTypes.length, targetGameTypes.length)) * gameTypeWeight;
    score += gameTypeScore;
  }
  maxScore += gameTypeWeight;
  
  // Availability Overlap (15% weight)
  const availabilityWeight = 15;
  const userAvailability = userProfile.availability || {};
  const targetAvailability = targetProfile.availability || {};
  
  let availabilityOverlap = 0;
  let totalSlots = 0;
  
  Object.keys(userAvailability).forEach(day => {
    if (targetAvailability[day]) {
      const userSlots = userAvailability[day] || [];
      const targetSlots = targetAvailability[day] || [];
      const commonSlots = userSlots.filter(slot => targetSlots.includes(slot));
      availabilityOverlap += commonSlots.length;
      totalSlots += Math.max(userSlots.length, targetSlots.length);
    }
  });
  
  if (totalSlots > 0) {
    const availabilityScore = (availabilityOverlap / totalSlots) * availabilityWeight;
    score += availabilityScore;
  }
  maxScore += availabilityWeight;
  
  // Normalize score to 0-100 range
  return maxScore > 0 ? Math.round((score / maxScore) * 100) : 0;
}

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Global error handler:', err);
  res.status(500).json({ error: err.message });
});

// ================================
// CHAT ENDPOINTS
// ================================

// Get user's chat list
app.get('/api/chats/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const chats = await Chat.find({
      participants: userId
    }).sort({ updatedAt: -1 });
    
    // Enrich chats with participant profile info and online status
    const enrichedChats = await Promise.all(
      chats.map(async (chat) => {
        const otherParticipant = chat.participants.find(p => p !== userId);
        const otherProfile = await Profile.findOne({ userId: otherParticipant });
        const userStatus = await UserStatus.findOne({ userId: otherParticipant });
        
        // Consider user offline if no update in last 5 minutes
        const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
        const isOnline = userStatus && userStatus.isOnline && userStatus.updatedAt > fiveMinutesAgo;
        
        return {
          _id: chat._id,
          participants: chat.participants,
          lastMessage: chat.lastMessage,
          unreadCount: chat.unreadCounts?.get(userId) || 0,
          otherUser: otherProfile ? {
            id: otherProfile.userId,
            name: `${otherProfile.profile.firstName || ''} ${otherProfile.profile.lastName || ''}`.trim() || 'Unknown User',
            photo: otherProfile.profile.profileImageUrl || otherProfile.profile.photos?.[0] || null,
            isOnline: isOnline,
            lastSeen: userStatus ? userStatus.lastSeen : null
          } : null,
          createdAt: chat.createdAt,
          updatedAt: chat.updatedAt
        };
      })
    );
    
    res.json({ success: true, chats: enrichedChats });
  } catch (error) {
    console.error('Error fetching chats:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get or create chat between two users
app.post('/api/chats/create', async (req, res) => {
  try {
    const { userId1, userId2 } = req.body;
    
    if (!userId1 || !userId2) {
      return res.status(400).json({ error: 'Both user IDs are required' });
    }
    
    // Check if chat already exists
    let chat = await Chat.findOne({
      participants: { $all: [userId1, userId2] }
    });
    
    if (!chat) {
      // Create new chat
      chat = new Chat({
        participants: [userId1, userId2],
        unreadCounts: new Map([
          [userId1, 0],
          [userId2, 0]
        ])
      });
      await chat.save();
    }
    
    res.json({ success: true, chatId: chat._id });
  } catch (error) {
    console.error('Error creating chat:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get messages for a chat
app.get('/api/chats/:chatId/messages', async (req, res) => {
  try {
    const { chatId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    
    const messages = await Message.find({ chatId })
      .sort({ timestamp: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);
    
    res.json({ success: true, messages: messages.reverse() });
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ error: error.message });
  }
});

// Send a message
app.post('/api/chats/:chatId/messages', async (req, res) => {
  try {
    const { chatId } = req.params;
    const { senderId, message, type = 'text' } = req.body;
    
    if (!senderId || !message) {
      return res.status(400).json({ error: 'Sender ID and message are required' });
    }
    
    // Create new message
    const newMessage = new Message({
      chatId,
      senderId,
      message,
      type,
      timestamp: new Date()
    });
    
    await newMessage.save();
    
    // Update chat's last message and unread counts
    const chat = await Chat.findById(chatId);
    if (chat) {
      chat.lastMessage = {
        senderId,
        message,
        timestamp: new Date(),
        type
      };
      chat.updatedAt = new Date();
      
      // Increment unread count for other participants
      chat.participants.forEach(participantId => {
        if (participantId !== senderId) {
          const currentCount = chat.unreadCounts.get(participantId) || 0;
          chat.unreadCounts.set(participantId, currentCount + 1);
        }
      });
      
      await chat.save();
    }
    
    res.json({ success: true, message: newMessage });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ error: error.message });
  }
});

// Mark messages as read
app.patch('/api/chats/:chatId/read', async (req, res) => {
  try {
    const { chatId } = req.params;
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }
    
    // Mark all messages in chat as read for this user
    await Message.updateMany(
      { chatId, senderId: { $ne: userId } },
      { isRead: true }
    );
    
    // Reset unread count for this user
    const chat = await Chat.findById(chatId);
    if (chat) {
      chat.unreadCounts.set(userId, 0);
      await chat.save();
    }
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error marking messages as read:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add reaction to message
app.post('/api/messages/:messageId/reactions', async (req, res) => {
  try {
    const { messageId } = req.params;
    const { userId, emoji } = req.body;
    
    if (!userId || !emoji) {
      return res.status(400).json({ error: 'User ID and emoji are required' });
    }
    
    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }
    
    // Check if user already reacted with this emoji
    const existingReaction = message.reactions.find(r => r.userId === userId && r.emoji === emoji);
    
    if (existingReaction) {
      // Remove reaction
      message.reactions = message.reactions.filter(r => !(r.userId === userId && r.emoji === emoji));
    } else {
      // Add reaction
      message.reactions.push({ userId, emoji });
    }
    
    await message.save();
    res.json({ success: true, reactions: message.reactions });
  } catch (error) {
    console.error('Error adding reaction:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete a message
app.delete('/api/messages/:messageId', async (req, res) => {
  try {
    const { messageId } = req.params;
    const { userId } = req.body;
    
    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }
    
    if (message.senderId !== userId) {
      return res.status(403).json({ error: 'Not authorized to delete this message' });
    }
    
    await Message.findByIdAndDelete(messageId);
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting message:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get chat info with participant details
app.get('/api/chats/info/:chatId', async (req, res) => {
  try {
    const { chatId } = req.params;
    
    const chat = await Chat.findById(chatId);
    if (!chat) {
      return res.status(404).json({ error: 'Chat not found' });
    }
    
    // Get participant profiles and their online status
    const participantProfiles = await Promise.all(
      chat.participants.map(async (userId) => {
        const profile = await Profile.findOne({ userId });
        const userStatus = await UserStatus.findOne({ userId });
        
        // Consider user offline if no update in last 5 minutes
        const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
        const isOnline = userStatus && userStatus.isOnline && userStatus.updatedAt > fiveMinutesAgo;
        
        return profile ? {
          id: profile.userId,
          name: `${profile.profile.firstName || ''} ${profile.profile.lastName || ''}`.trim() || 'Unknown User',
          photo: profile.profile.profileImageUrl || profile.profile.photos?.[0] || null,
          isOnline: isOnline,
          lastSeen: userStatus ? userStatus.lastSeen : null
        } : null;
      })
    );
    
    const enrichedChat = {
      _id: chat._id,
      participants: chat.participants,
      lastMessage: chat.lastMessage,
      participantDetails: participantProfiles.filter(p => p !== null),
      unreadCounts: chat.unreadCounts,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt
    };
    
    res.json(enrichedChat);
  } catch (error) {
    console.error('Error getting chat info:', error);
    res.status(500).json({ error: error.message });
  }
});

// User Status Endpoints

// Update user online status
app.post('/api/users/:userId/status', async (req, res) => {
  try {
    const { userId } = req.params;
    const { isOnline, platform, version, userAgent } = req.body;
    
    const statusUpdate = {
      userId,
      isOnline: isOnline !== undefined ? isOnline : true,
      lastSeen: new Date(),
      deviceInfo: {
        platform: platform || 'unknown',
        version: version || 'unknown',
        userAgent: userAgent || 'unknown'
      },
      updatedAt: new Date()
    };
    
    const userStatus = await UserStatus.findOneAndUpdate(
      { userId },
      statusUpdate,
      { upsert: true, new: true }
    );
    
    res.json({ success: true, userStatus });
  } catch (error) {
    console.error('Error updating user status:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get user status
app.get('/api/users/:userId/status', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const userStatus = await UserStatus.findOne({ userId });
    if (!userStatus) {
      return res.json({
        userId,
        isOnline: false,
        lastSeen: null
      });
    }
    
    // Consider user offline if no update in last 5 minutes
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    const isActuallyOnline = userStatus.isOnline && userStatus.updatedAt > fiveMinutesAgo;
    
    res.json({
      userId: userStatus.userId,
      isOnline: isActuallyOnline,
      lastSeen: userStatus.lastSeen,
      deviceInfo: userStatus.deviceInfo
    });
  } catch (error) {
    console.error('Error getting user status:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get multiple users' status
app.post('/api/users/status/batch', async (req, res) => {
  try {
    const { userIds } = req.body;
    
    if (!Array.isArray(userIds)) {
      return res.status(400).json({ error: 'userIds must be an array' });
    }
    
    const userStatuses = await UserStatus.find({ userId: { $in: userIds } });
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    
    const statusMap = {};
    userStatuses.forEach(status => {
      const isActuallyOnline = status.isOnline && status.updatedAt > fiveMinutesAgo;
      statusMap[status.userId] = {
        userId: status.userId,
        isOnline: isActuallyOnline,
        lastSeen: status.lastSeen,
        deviceInfo: status.deviceInfo
      };
    });
    
    // Fill in missing users as offline
    userIds.forEach(userId => {
      if (!statusMap[userId]) {
        statusMap[userId] = {
          userId,
          isOnline: false,
          lastSeen: null
        };
      }
    });
    
    res.json({ statuses: statusMap });
  } catch (error) {
    console.error('Error getting batch user status:', error);
    res.status(500).json({ error: error.message });
  }
});

// Set user offline (for logout)
app.post('/api/users/:userId/offline', async (req, res) => {
  try {
    const { userId } = req.params;
    
    await UserStatus.findOneAndUpdate(
      { userId },
      { 
        isOnline: false, 
        lastSeen: new Date(),
        updatedAt: new Date()
      },
      { upsert: true }
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error setting user offline:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============ WISHLIST ENDPOINTS ============

// Get user's wishlists
app.get('/api/wishlists/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`📋 Fetching wishlists for user: ${userId}`);
    
    const wishlists = await Wishlist.find({ userId }).sort({ updatedAt: -1 });
    console.log(`✅ Found ${wishlists.length} wishlists for user ${userId}`);
    
    res.json(wishlists);
  } catch (error) {
    console.error('Error fetching wishlists:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create a new wishlist
app.post('/api/wishlists', async (req, res) => {
  try {
    const { name, userId, venueIds = [] } = req.body;
    
    if (!name || !userId) {
      return res.status(400).json({ error: 'Name and userId are required' });
    }
    
    if (name.length > 50) {
      return res.status(400).json({ error: 'Wishlist name cannot exceed 50 characters' });
    }
    
    console.log(`📝 Creating new wishlist: "${name}" for user: ${userId}`);
    
    const newWishlist = new Wishlist({
      name: name.trim(),
      userId,
      venueIds,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    await newWishlist.save();
    console.log(`✅ Created wishlist with ID: ${newWishlist._id}`);
    
    res.status(201).json(newWishlist);
  } catch (error) {
    console.error('Error creating wishlist:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add venue to wishlist
app.post('/api/wishlists/:wishlistId/venues', async (req, res) => {
  try {
    const { wishlistId } = req.params;
    const { venueId } = req.body;
    
    if (!venueId) {
      return res.status(400).json({ error: 'venueId is required' });
    }
    
    console.log(`➕ Adding venue ${venueId} to wishlist ${wishlistId}`);
    
    const wishlist = await Wishlist.findById(wishlistId);
    if (!wishlist) {
      return res.status(404).json({ error: 'Wishlist not found' });
    }
    
    // Check if venue is already in the wishlist
    if (wishlist.venueIds.includes(venueId)) {
      return res.status(400).json({ error: 'Venue is already in this wishlist' });
    }
    
    wishlist.venueIds.push(venueId);
    wishlist.updatedAt = new Date();
    
    await wishlist.save();
    console.log(`✅ Added venue to wishlist. Total venues: ${wishlist.venueIds.length}`);
    
    res.json(wishlist);
  } catch (error) {
    console.error('Error adding venue to wishlist:', error);
    res.status(500).json({ error: error.message });
  }
});

// Remove venue from wishlist
app.delete('/api/wishlists/:wishlistId/venues/:venueId', async (req, res) => {
  try {
    const { wishlistId, venueId } = req.params;
    
    console.log(`➖ Removing venue ${venueId} from wishlist ${wishlistId}`);
    
    const wishlist = await Wishlist.findById(wishlistId);
    if (!wishlist) {
      return res.status(404).json({ error: 'Wishlist not found' });
    }
    
    const venueIndex = wishlist.venueIds.indexOf(venueId);
    if (venueIndex === -1) {
      return res.status(404).json({ error: 'Venue not found in this wishlist' });
    }
    
    wishlist.venueIds.splice(venueIndex, 1);
    wishlist.updatedAt = new Date();
    
    await wishlist.save();
    console.log(`✅ Removed venue from wishlist. Remaining venues: ${wishlist.venueIds.length}`);
    
    res.json(wishlist);
  } catch (error) {
    console.error('Error removing venue from wishlist:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete wishlist
app.delete('/api/wishlists/:wishlistId', async (req, res) => {
  try {
    const { wishlistId } = req.params;
    
    console.log(`🗑️ Deleting wishlist: ${wishlistId}`);
    
    // Validate wishlistId format
    if (!wishlistId || wishlistId.length !== 24) {
      console.log(`❌ Invalid wishlist ID format: ${wishlistId}`);
      return res.status(400).json({ error: 'Invalid wishlist ID format' });
    }
    
    const wishlist = await Wishlist.findByIdAndDelete(wishlistId);
    if (!wishlist) {
      console.log(`❌ Wishlist not found: ${wishlistId}`);
      return res.status(404).json({ error: 'Wishlist not found' });
    }
    
    console.log(`✅ Deleted wishlist: "${wishlist.name}"`);
    res.json({ success: true, message: 'Wishlist deleted successfully' });
  } catch (error) {
    console.error('❌ Error deleting wishlist:', error);
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      name: error.name
    });
    res.status(500).json({ error: error.message });
  }
});

// Get wishlist by ID (for wishlist details page)
app.get('/api/wishlists/:wishlistId', async (req, res) => {
  try {
    const { wishlistId } = req.params;
    
    console.log(`📋 Fetching wishlist: ${wishlistId}`);
    
    const wishlist = await Wishlist.findById(wishlistId);
    if (!wishlist) {
      return res.status(404).json({ error: 'Wishlist not found' });
    }
    
    console.log(`✅ Found wishlist: "${wishlist.name}" with ${wishlist.venueIds.length} venues`);
    res.json(wishlist);
  } catch (error) {
    console.error('Error fetching wishlist:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update wishlist name
app.put('/api/wishlists/:wishlistId', async (req, res) => {
  try {
    const { wishlistId } = req.params;
    const { name } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Name is required' });
    }
    
    if (name.length > 50) {
      return res.status(400).json({ error: 'Wishlist name cannot exceed 50 characters' });
    }
    
    console.log(`✏️ Updating wishlist ${wishlistId} name to: "${name}"`);
    
    const wishlist = await Wishlist.findByIdAndUpdate(
      wishlistId,
      { 
        name: name.trim(),
        updatedAt: new Date()
      },
      { new: true }
    );
    
    if (!wishlist) {
      return res.status(404).json({ error: 'Wishlist not found' });
    }
    
    console.log(`✅ Updated wishlist name successfully`);
    res.json(wishlist);
  } catch (error) {
    console.error('Error updating wishlist:', error);
    res.status(500).json({ error: error.message });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`MongoDB API Server running on port ${PORT}`);
  console.log(`API available at http://localhost:${PORT}/api`);
});
