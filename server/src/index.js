require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const usernameRoutes = require('./routes/usernameRoutes');
const userProfileRoutes = require('./routes/userProfileRoutes');

// Initialize express app
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors({
  // Allow requests from specific origins
  origin: ['http://localhost:3000', 'http://localhost', 'http://localhost:8080', 'http://localhost:8000', 'http://127.0.0.1', 'http://127.0.0.1:8000', 'http://127.0.0.1:8080', 'http://127.0.0.1:3000', 'http://localhost:52946', 'http://localhost:53489', 'http://localhost:55914', 'http://localhost:58664', 'http://localhost:54115', 'http://localhost:62191', 'http://localhost:51543', 'http://localhost:54137', 'http://localhost:58739', 'http://[::1]', 'capacitor://localhost', 'ionic://localhost'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  credentials: true,
  maxAge: 86400, // 24 hours
  preflightContinue: false,
  optionsSuccessStatus: 204
}));

// Add CORS headers manually for any response
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  
  next();
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Add request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  console.log('Health check requested');
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    dbConnected: app.locals.dbConnected || false,
    server: 'billiards_hub_api'
  });
});

// MongoDB connection configuration
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/billiards_hub';

// Set mongoose options
mongoose.set('strictQuery', false);

// MongoDB connection options
const mongooseOptions = {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  connectTimeoutMS: 10000,
  retryWrites: true,
  retryReads: true,
  maxPoolSize: 50,
  minPoolSize: 10,
};

// Connect to MongoDB with retry logic
const connectToMongoDB = async (retryCount = 0, maxRetries = 3) => {
  try {
    await mongoose.connect(MONGODB_URI, mongooseOptions);
    console.log('MongoDB connected successfully');
    app.locals.dbConnected = true;

    // Add connection error handler
    mongoose.connection.on('error', (err) => {
      console.error('MongoDB connection error:', err);
      attemptReconnection();
    });

    // Add disconnection handler
    mongoose.connection.on('disconnected', () => {
      console.log('MongoDB disconnected. Attempting to reconnect...');
      attemptReconnection();
    });

  } catch (err) {
    console.error(`MongoDB connection attempt ${retryCount + 1} failed:`, err);
    
    if (retryCount < maxRetries) {
      const retryDelay = Math.min(1000 * Math.pow(2, retryCount), 10000);
      console.log(`Retrying connection in ${retryDelay}ms...`);
      
      setTimeout(() => {
        connectToMongoDB(retryCount + 1, maxRetries);
      }, retryDelay);
    } else {
      console.error('Max retry attempts reached. Could not connect to MongoDB.');
      app.locals.dbConnected = false;
    }
  }
};

// Helper function to attempt reconnection
const attemptReconnection = () => {
  if (!app.locals.dbConnected) return; // Prevent multiple reconnection attempts
  app.locals.dbConnected = false;
  setTimeout(() => {
    console.log('Attempting to reconnect to MongoDB...');
    connectToMongoDB();
  }, 5000);
};

connectToMongoDB();

// Routes
app.use('/api/username', usernameRoutes);
app.use('/api/profile', userProfileRoutes);

// Health check route - doesn't require DB connection
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    message: 'Server is running', 
    time: new Date().toISOString(), 
    env: process.env.NODE_ENV,
    dbConnected: app.locals.dbConnected 
  });
});

// Test route for username availability
app.get('/api/username/debug-check', (req, res) => {
  const username = req.query.username;
  console.log(`Debug check for username: ${username}`);
  console.log(`Headers:`, req.headers);
  res.status(200).json({
    received: true,
    username,
    headers: req.headers,
    time: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong on the server',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
