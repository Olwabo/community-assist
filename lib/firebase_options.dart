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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnFODrmjpzBaqWHA9XKEMKw2IQDxd2DJo',
    appId: '1:922044991896:web:8baaeacc7f968b56f483ed',
    messagingSenderId: '922044991896',
    projectId: 'community-assist-c6ac6',
    authDomain: 'community-assist-c6ac6.firebaseapp.com',
    storageBucket: 'community-assist-c6ac6.firebasestorage.app',
    measurementId: 'G-M72HVV6S5C',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2jfgCDQ4ZLltS7A8r0JqjJPK-wfAMmFY',
    appId: '1:922044991896:android:d928e2fe99215d79f483ed',
    messagingSenderId: '922044991896',
    projectId: 'community-assist-c6ac6',
    storageBucket: 'community-assist-c6ac6.firebasestorage.app',
  );
}
