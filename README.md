# Billiards Hub - Sports Venue & Matchmaking Platform

A comprehensive Flutter application for managing sports venues, matchmaking players, and building a community around recreational sports.

##  Overview

Billiards Hub is a cross-platform application that connects sports enthusiasts with venues and players. The app features intelligent matchmaking, real-time chat, venue discovery, and wishlist management.

##  Features

-  **Venue Discovery** - Browse and explore sports venues with detailed information
-  **Smart Matchmaking** - Tinder-style interface to find compatible playing partners
-  **Real-time Chat** - Communicate with matched players instantly
-  **Location-based Search** - Find venues and players near you
-  **Wishlist Management** - Save your favorite venues
-  **Push Notifications** - Stay updated with matches and messages
-  **User Profiles** - Customizable profiles with skill levels and preferences
-  **Multiple Sports** - Bowling, Billiards, Snooker, Mini Golf, Table Tennis, Darts, and more

##  Quick Start

**See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed setup instructions.**

### Prerequisites
- Flutter SDK (latest stable)
- Node.js v14+
- MongoDB Atlas account
- Firebase account

### Basic Setup
\\\ash
# Clone repository
git clone https://github.com/yourusername/billiards_hub.git
cd billiards_hub

# Install Flutter dependencies
flutter pub get

# Setup server
cd server
npm install
cp .env.example .env
# Edit .env with your MongoDB credentials

# Run server
npm run dev

# Run app (from root)
flutter run
\\\

##  Configuration Required

Before running, you need to configure:

1. **Firebase** - Copy \lib/firebase_options.dart.example\ to \lib/firebase_options.dart\ and add your credentials
2. **Google Services** - Copy \ndroid/app/google-services.json.example\ and add your file
3. **MongoDB** - Copy \server/.env.example\ to \server/.env\ and add your connection string

See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed instructions.

##  Platform Support

-  Android
-  iOS
-  Web
-  Windows
-  macOS
-  Linux

##  Tech Stack

### Frontend
- **Flutter** - Cross-platform framework
- **Riverpod** - State management
- **go_router** - Navigation
- **Firebase** - Authentication & messaging

### Backend
- **Node.js + Express** - REST API
- **MongoDB** - Database
- **Mongoose** - ODM

##  Project Structure

\\\
billiards_hub/
 lib/
    src/
       models/          # Data models
       providers/       # State management
       screens/         # UI screens
       services/        # API services
       widgets/         # Reusable components
    main.dart
 server/
    models/              # MongoDB schemas
    routes/              # API endpoints
    server.js            # Express server
 docs/                    # Documentation
\\\

##  Security

 **Never commit these files:**
- \server/.env\
- \lib/firebase_options.dart\
- \ndroid/app/google-services.json\

Example files are provided with \.example\ extension.

##  Documentation

- [Setup Guide](./SETUP_GUIDE.md) - Complete setup instructions
- [Web MongoDB Implementation](./docs/web_mongodb_implementation.md)
- [Notification API](./docs/notification_api_specification.md)


##  License

MIT License - see LICENSE file for details

---

Made with Flutter
