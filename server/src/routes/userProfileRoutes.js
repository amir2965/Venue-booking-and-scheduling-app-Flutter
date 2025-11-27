const express = require('express');
const router = express.Router();
const userProfileController = require('../controllers/userProfileController');

// Get user profile by userId
router.get('/:userId', userProfileController.getUserProfile);

// Create or update user profile
router.put('/:userId', userProfileController.updateUserProfile);

// Check if username is available
router.get('/check-username/:username', userProfileController.checkUsername);

module.exports = router;
