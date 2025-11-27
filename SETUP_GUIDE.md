# Billiards Hub

A Flutter application for managing billiards venues, matchmaking, and social features.

## Features

- 🎱 Venue discovery and exploration
- 👥 User matchmaking system
- 💬 Real-time chat functionality
- 🔔 Push notifications
- 📱 Cross-platform support (Android, iOS, Web)
- 🗂️ Wishlist management for venues

## Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (latest stable version)
- Node.js (v14 or higher)
- MongoDB Atlas account
- Firebase account

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/billiards_hub.git
cd billiards_hub
```

### 2. Flutter Setup

Install Flutter dependencies:

```bash
flutter pub get
```

### 3. Firebase Configuration

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Firebase Authentication, Firestore, and Cloud Messaging
3. Download your Firebase configuration files:
   - For Android: Download `google-services.json` and place it in `android/app/`
   - For iOS: Download `GoogleService-Info.plist` and place it in `ios/Runner/`
4. Run FlutterFire CLI to generate configuration:

```bash
flutterfire configure
```

This will create `lib/firebase_options.dart` with your Firebase credentials.

Alternatively, copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart` and fill in your Firebase credentials.

### 4. MongoDB Setup

1. Create a MongoDB Atlas account at [mongodb.com](https://www.mongodb.com/cloud/atlas)
2. Create a new cluster
3. Create a database user with read/write permissions
4. Whitelist your IP address or use `0.0.0.0/0` for development
5. Get your connection string

### 5. Server Configuration

Navigate to the server directory and install dependencies:

```bash
cd server
npm install
```

Create a `.env` file in the `server` directory by copying the example:

```bash
cp .env.example .env
```

Edit `.env` and add your MongoDB connection string:

```env
PORT=5000
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/billiards_hub?retryWrites=true&w=majority
NODE_ENV=development
```

Replace:
- `username` with your MongoDB username
- `password` with your MongoDB password
- `cluster` with your cluster address
- `billiards_hub` with your database name

### 6. Running the Application

#### Start the Backend Server

```bash
cd server
npm run dev
```

The server will run on `http://localhost:5000`

#### Run the Flutter App

From the project root:

```bash
flutter run
```

Or for web:

```bash
flutter run -d chrome
```

## Project Structure

```
billiards_hub/
├── lib/
│   ├── src/
│   │   ├── models/          # Data models
│   │   ├── providers/       # Riverpod state management
│   │   ├── screens/         # UI screens
│   │   ├── services/        # API and database services
│   │   └── widgets/         # Reusable widgets
│   └── main.dart
├── server/
│   ├── models/              # MongoDB schemas
│   ├── routes/              # API routes
│   └── server.js            # Express server
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
└── web/                     # Web-specific files
```

## Environment Variables

### Server (.env)
- `PORT` - Server port (default: 5000)
- `MONGODB_URI` - MongoDB connection string
- `NODE_ENV` - Environment (development/production)

### Flutter
MongoDB credentials are configured via `--dart-define` flags in the MongoDB service files.

## Building for Production

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## Security Notes

⚠️ **Important**: Never commit sensitive files to version control:
- `server/.env`
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

These files are already included in `.gitignore`.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email your-email@example.com or open an issue in the GitHub repository.
