const mongoose = require('mongoose');

// Player profile schema
const playerProfileSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    unique: true
  },
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  displayName: {
    type: String,
    required: false,
    trim: true
  },
  avatarUrl: {
    type: String,
    required: false
  },
  stats: {
    gamesPlayed: {
      type: Number,
      default: 0
    },
    gamesWon: {
      type: Number,
      default: 0
    },
    winPercentage: {
      type: Number,
      default: 0
    }
  },
  preferences: {
    theme: {
      type: String,
      default: 'light'
    },
    notifications: {
      type: Boolean,
      default: true
    }
  },
  lastActive: {
    type: Date,
    default: Date.now
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Create indexes for faster lookups
playerProfileSchema.index({ userId: 1 });
playerProfileSchema.index({ username: 1 });

// Virtual for win percentage calculation
playerProfileSchema.virtual('winRate').get(function() {
  if (this.stats.gamesPlayed === 0) return 0;
  return (this.stats.gamesWon / this.stats.gamesPlayed * 100).toFixed(2);
});

const PlayerProfile = mongoose.model('PlayerProfile', playerProfileSchema);

module.exports = PlayerProfile;
