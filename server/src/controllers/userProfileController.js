const UserProfile = require('../models/userProfile');

// Get a user profile by userId
exports.getUserProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    
    const userProfile = await UserProfile.findOne({ userId });
    
    if (!userProfile) {
      return res.status(404).json({ 
        success: false, 
        message: 'User profile not found' 
      });
    }
    
    console.log(`Retrieved profile for user ${userId}:`);
    console.log(`  firstName: ${userProfile.firstName}`);
    console.log(`  username: ${userProfile.username}`);
    console.log(`  skillLevel: ${userProfile.skillLevel}`);
    console.log(`  skillTier: ${userProfile.skillTier}`);
    
    return res.status(200).json({
      success: true,
      data: userProfile
    });
  } catch (error) {
    console.error('Error getting user profile:', error);
    return res.status(500).json({
      success: false,
      message: 'Error getting user profile',
      error: error.message
    });
  }
};

// Create or update a user profile
exports.updateUserProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    const profileData = req.body;
    
    // Add validation for required fields
    if (!profileData.username) {
      return res.status(400).json({
        success: false,
        message: 'Username is required'
      });
    }
    
    // Check if username is already taken by another user
    const existingUsername = await UserProfile.findOne({ 
      username: profileData.username,
      userId: { $ne: userId }
    });
    
    if (existingUsername) {
      return res.status(400).json({
        success: false,
        message: 'Username is already taken'
      });
    }
    
    // Save both the numeric skillLevel and the string skillTier
    // Preserve the user-selected skillTier even if it doesn't match the calculated one
    console.log(`Incoming data - skillLevel: ${profileData.skillLevel}, skillTier: ${profileData.skillTier}`);
    
    // Ensure skillTier is set correctly if not provided
    if (!profileData.skillTier && profileData.skillLevel) {
      if (profileData.skillLevel <= 1.0) profileData.skillTier = 'Novice';
      else if (profileData.skillLevel <= 2.0) profileData.skillTier = 'Beginner';
      else if (profileData.skillLevel <= 3.0) profileData.skillTier = 'Intermediate';
      else if (profileData.skillLevel <= 4.0) profileData.skillTier = 'Advanced';
      else profileData.skillTier = 'Pro';
      console.log(`No skillTier provided, calculated from level: ${profileData.skillTier}`);
    }
    
    // Log the incoming data with detailed field-by-field output
    console.log(`Updating profile for user ${userId} with data:`);
    console.log(`  firstName: ${profileData.firstName || 'not provided'}`);
    console.log(`  username: ${profileData.username}`);
    console.log(`  skillLevel: ${profileData.skillLevel}`);
    console.log(`  skillTier: ${profileData.skillTier}`);
    
    // Find and update or create new profile
    const userProfile = await UserProfile.findOneAndUpdate(
      { userId },
      { 
        ...profileData,
        userId, // Ensure userId is included
        updatedAt: Date.now()
      },
      { 
        new: true,
        upsert: true,
        setDefaultsOnInsert: true
      }
    );
    
    console.log(`Profile updated for user ${userId}:`);
    console.log(`  firstName: ${userProfile.firstName || 'not set'}`);
    console.log(`  username: ${userProfile.username}`);
    console.log(`  skillLevel: ${userProfile.skillLevel}`);
    console.log(`  skillTier: ${userProfile.skillTier}`);
    
    return res.status(200).json({
      success: true,
      data: userProfile,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('Error updating user profile:', error);
    return res.status(500).json({
      success: false,
      message: 'Error updating user profile',
      error: error.message
    });
  }
};

// Check if username is available
exports.checkUsername = async (req, res) => {
  try {
    const { username } = req.params;
    
    // Validate username format
    if (!username || username.length < 3) {
      return res.status(400).json({
        success: false,
        available: false,
        message: 'Username must be at least 3 characters'
      });
    }
    
    const userProfile = await UserProfile.findOne({ username });
    
    return res.status(200).json({
      success: true,
      available: !userProfile,
      message: userProfile ? 'Username is already taken' : 'Username is available'
    });
  } catch (error) {
    console.error('Error checking username:', error);
    return res.status(500).json({
      success: false,
      message: 'Error checking username',
      error: error.message
    });
  }
};
