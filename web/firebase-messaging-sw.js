importScripts('https://www.gstatic.com/firebasejs/9.17.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.17.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAYGPfM-kQ5jIZzRNN059ASTo2Wiy-CHd8",
  authDomain: "farmkart-9f4f3.firebaseapp.com",
  databaseURL: "https://farmkart-9f4f3-default-rtdb.firebaseio.com",
  projectId: "farmkart-9f4f3",
  storageBucket: "farmkart-9f4f3.firebasestorage.app",
  messagingSenderId: "709785957438",
  appId: "1:709785957438:android:2f747a5a153a33b0134d6f", // Note: Web appId might differ but this matches your firebase_options.dart
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  return self.registration.showNotification(notificationTitle,
    notificationOptions);
});
