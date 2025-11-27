const mongoose = require('mongoose');

const userProfileSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    unique: true
  },
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    minlength: 3,
    maxlength: 20
  },
  firstName: {
    type: String,
    trim: true
  },
  email: {
    type: String,
    trim: true
  },
  gender: {
    type: String,
    trim: true
  },  skillLevel: {
    type: Number,
    default: 1.0
  },
  skillTier: {
    type: String,
    default: 'Novice',
    enum: ['Novice', 'Beginner', 'Intermediate', 'Advanced', 'Pro']
  },
  bio: String,
  preferredGameTypes: [String],
  availability: {
    type: Map,
    of: [String]
  },
  preferredLocation: String,
  experiencePoints: {
    type: Number,
    default: 10
  },
  matchesPlayed: {
    type: Number,
    default: 0
  },
  achievements: [String],
  winRate: Number,
  playStyle: String,
  showInPartnerMatching: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Add a pre-save hook to update the updatedAt field
userProfileSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Create a model from the schema
const UserProfile = mongoose.model('UserProfile', userProfileSchema);

module.exports = UserProfile;
