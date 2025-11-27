const mongoose = require('mongoose');

// Username schema
const usernameSchema = new mongoose.Schema({  username: {
    type: String,
    required: true,
    trim: true,
    lowercase: true
  },
  userId: {
    type: String,
    required: true
  },
  displayUsername: {
    type: String,
    required: true,
    trim: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Create indexes for faster lookups
usernameSchema.index({ username: 1 });
usernameSchema.index({ userId: 1 });

const Username = mongoose.model('Username', usernameSchema);

module.exports = Username;
