// Firebase Cloud Messaging worker for Terai web notifications.
// The configuration below is public browser configuration, not an Admin SDK key.
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyB7Utk1T19uPGDU-X2TFed8lhdqGZK2y4U',
  authDomain: 'foundervers-mobile-project.firebaseapp.com',
  projectId: 'foundervers-mobile-project',
  storageBucket: 'foundervers-mobile-project.firebasestorage.app',
  messagingSenderId: '726949218868',
  appId: '1:726949218868:web:c9a90b8be4678a9a949861',
  measurementId: 'G-FBHSVG05V1',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const title = notification.title || 'Terai';
  const options = {
    body: notification.body || 'You have a new notification.',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  };
  self.registration.showNotification(title, options);
});
