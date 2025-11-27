// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAt05j02Wh4711p8EZb4hc7RFz1i42rUzc",
  authDomain: "pool-4b84e.firebaseapp.com",
  projectId: "pool-4b84e",
  storageBucket: "pool-4b84e.appspot.com",
  messagingSenderId: "428298560491",
  appId: "1:428298560491:web:60f4792318cb7fa2872fae"
};

// Initialize Firebase
if (typeof window !== 'undefined') {
  firebase.initializeApp(firebaseConfig);
}