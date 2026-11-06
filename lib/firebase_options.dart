import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Public Firebase configuration for the Terai web application.
///
/// These identifiers are intentionally browser-visible. Private Firebase Admin
/// credentials remain in Supabase Edge Function secrets only.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Terai is configured as a web application.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7Utk1T19uPGDU-X2TFed8lhdqGZK2y4U',
    appId: '1:726949218868:web:c9a90b8be4678a9a949861',
    messagingSenderId: '726949218868',
    projectId: 'foundervers-mobile-project',
    authDomain: 'foundervers-mobile-project.firebaseapp.com',
    storageBucket: 'foundervers-mobile-project.firebasestorage.app',
    measurementId: 'G-FBHSVG05V1',
  );
}
