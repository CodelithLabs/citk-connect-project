import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } 
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - ',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - ',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - ',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCBZQwuhDJ0abN5cAH8trJSU0U1AO_cz0s',
    appId: '1:895444402352:web:22eaf2a0c153f59e03fb75',
    messagingSenderId: '895444402352',
    projectId: 'citk-connect-core',
    authDomain: 'citk-connect-core.firebaseapp.com',
    storageBucket: 'citk-connect-core.firebasestorage.app',
    measurementId: 'G-KDNMWLC7SR',
  );

   static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADehtCqyvIEFsK6pltjW7Np6I-xExXfUQ',
    appId: '1:895444402352:android:9d124a82383f9ca103fb75',
    messagingSenderId: '895444402352',
    projectId: 'citk-connect-core',
    storageBucket: 'citk-connect-core.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAoX4whWyKKZMn9rzW9ngtoSj6Wwn75Khg',
    appId: '1:895444402352:ios:1644dc25a938971603fb75',
    messagingSenderId: '895444402352',
    projectId: 'citk-connect-core',
    storageBucket: 'citk-connect-core.firebasestorage.app',
    iosBundleId: 'com.example.myapp',
  );

}