# Notification System Backend Endpoints

This document outlines the backend API endpoints required for the bidirectional match notification system.

## Base URL
```
http://localhost:5000/api/notifications
```

## Endpoints

### 1. Create Notification
**POST** `/notifications`

Creates a new notification for a user.

**Request Body:**
```json
{
  "userId": "string",
  "type": "string", // "match", "message", "like", "general"
  "relatedUserId": "string",
  "message": "string",
  "isRead": false,
  "createdAt": "ISO 8601 date string"
}
```

**Response:**
```json
{
  "success": true,
  "notification": {
    "_id": "generated_id",
    "userId": "string",
    "type": "string",
    "relatedUserId": "string",
    "message": "string",
    "isRead": false,
    "createdAt": "ISO 8601 date string"
  }
}
```

### 2. Get User Notifications
**GET** `/notifications/:userId`

**Query Parameters:**
- `unreadOnly` (boolean, optional): Return only unread notifications
- `limit` (number, optional): Maximum number of notifications to return (default: 50)

**Response:**
```json
{
  "success": true,
  "notifications": [
    {
      "_id": "string",
      "userId": "string",
      "type": "string",
      "relatedUserId": "string",
      "message": "string",
      "isRead": boolean,
      "createdAt": "ISO 8601 date string"
    }
  ]
}
```

### 3. Get Unread Notification Count
**GET** `/notifications/:userId/unread-count`

**Response:**
```json
{
  "count": number
}
```

### 4. Mark Notification as Read
**PATCH** `/notifications/:notificationId/read`

Marks a specific notification as read.

**Response:**
```json
{
  "success": true,
  "notification": {
    "_id": "string",
    "userId": "string",
    "type": "string",
    "relatedUserId": "string",
    "message": "string",
    "isRead": true,
    "createdAt": "ISO 8601 date string"
  }
}
```

### 5. Mark All Notifications as Read
**PATCH** `/notifications/:userId/mark-all-read`

Marks all notifications for a user as read.

**Response:**
```json
{
  "success": true,
  "message": "Marked X notifications as read",
  "modifiedCount": number
}
```

### 6. Delete Notification
**DELETE** `/notifications/:notificationId`

**Response:**
```json
{
  "success": true
}
```

## Database Schema

### Notifications Collection (MongoDB)
```javascript
{
  _id: ObjectId,
  userId: String, // The user who should receive the notification
  type: String, // "match", "message", "like", "general"
  relatedUserId: String, // The user who triggered the notification
  message: String, // The notification message
  isRead: Boolean, // Whether the user has seen this notification
  createdAt: Date, // When the notification was created
  updatedAt: Date // When the notification was last updated
}
```

### Indexes
```javascript
// For efficient queries
db.notifications.createIndex({ userId: 1, createdAt: -1 });
db.notifications.createIndex({ userId: 1, isRead: 1 });
db.notifications.createIndex({ createdAt: 1 }, { expireAfterSeconds: 2592000 }); // Auto-delete after 30 days
```

## Integration with Matchmaking

The matchmaking service should automatically create notifications when matches occur:

### When a Match Happens
1. User A likes User B
2. User B likes User A back → Match created
3. Backend creates two notifications:
   - For User A: "It's a match! [User B Name] liked you back!"
   - For User B: "It's a match! You and [User A Name] liked each other!"

### Example Implementation (Node.js)
```javascript
// When processing a like action that results in a match
async function handleMatchCreated(userAId, userBId, userAName, userBName) {
  await Promise.all([
    createNotification({
      userId: userAId,
      type: 'match',
      relatedUserId: userBId,
      message: `It's a match! ${userBName} liked you back!`,
      isRead: false,
      createdAt: new Date()
    }),
    createNotification({
      userId: userBId,
      type: 'match',
      relatedUserId: userAId,
      message: `It's a match! You and ${userAName} liked each other!`,
      isRead: false,
      createdAt: new Date()
    })
  ]);
}
```

## Push Notifications (Future Enhancement)

For push notifications when the app is in the background:
- Use Firebase Cloud Messaging (FCM) or Apple Push Notifications (APN)
- Store device tokens in user profiles
- Send push notifications when creating notifications for offline users
- Include notification data in push payload for deep linking

## Security Considerations

1. **Authentication**: All endpoints should require valid user authentication
2. **Authorization**: Users can only access their own notifications
3. **Rate Limiting**: Implement rate limiting to prevent spam
4. **Data Validation**: Validate all input data
5. **Privacy**: Don't expose sensitive user information in notifications
