// Mock API Server with in-memory storage
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// In-memory storage
const profiles = new Map();
const likes = [];

// Routes
// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Mock API is running' });
});

// Get all profiles
app.get('/api/profiles', (req, res) => {
  const allProfiles = Array.from(profiles.values());
  res.status(200).json(allProfiles);
});

// Get profile by ID
app.get('/api/profiles/:id', (req, res) => {
  const profile = profiles.get(req.params.id);
  if (!profile) {
    return res.status(404).json({ error: 'Profile not found' });
  }
  res.status(200).json(profile);
});

// Create profile
app.post('/api/profiles', (req, res) => {
  const { user, ...profileData } = req.body;
  const userId = user.id;
  
  // Check if profile already exists
  if (profiles.has(userId)) {
    return res.status(409).json({ error: 'Profile already exists' });
  }
  
  profiles.set(userId, req.body);
  console.log('New profile created for user:', userId);
  res.status(201).json(req.body);
});

// Update profile
app.put('/api/profiles/:id', (req, res) => {
  const profileId = req.params.id;
  
  if (!profiles.has(profileId)) {
    return res.status(404).json({ error: 'Profile not found' });
  }
  
  profiles.set(profileId, req.body);
  console.log('Profile updated for user:', profileId);
  res.status(200).json(req.body);
});

// Add like
app.post('/api/likes', (req, res) => {
  const { userId, likedProfileId, isMatch } = req.body;
  
  const newLike = { userId, likedProfileId, isMatch };
  likes.push(newLike);
  
  console.log(`User ${userId} liked profile ${likedProfileId}. Match: ${isMatch}`);
  res.status(201).json(newLike);
});

// Start server
app.listen(PORT, () => {
  console.log(`Mock API Server running on port ${PORT}`);
  console.log(`API available at http://localhost:${PORT}/api`);
  console.log('This is a fallback server that uses in-memory storage instead of MongoDB');
  console.log('All data will be lost when the server is restarted');
});
