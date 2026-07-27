import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyCHumxWKKMNwi9NCElr6WgIHD40QXbwLSQ',
    appId: '1:774263444012:web:204964d4bf4efef1237789',
    messagingSenderId: '774263444012',
    projectId: 'vanmitra-ai',
    authDomain: 'vanmitra-ai.firebaseapp.com',
    storageBucket: 'vanmitra-ai.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCHumxWKKMNwi9NCElr6WgIHD40QXbwLSQ',
    appId: '1:774263444012:android:d0acab07b289ea12237789',
    messagingSenderId: '774263444012',
    projectId: 'vanmitra-ai',
    storageBucket: 'vanmitra-ai.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCHumxWKKMNwi9NCElr6WgIHD40QXbwLSQ',
    appId: '1:774263444012:ios:204964d4bf4efef1237789',
    messagingSenderId: '774263444012',
    projectId: 'vanmitra-ai',
    storageBucket: 'vanmitra-ai.firebasestorage.app',
    iosBundleId: 'com.vanmitra.vanmitra_ai',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCHumxWKKMNwi9NCElr6WgIHD40QXbwLSQ',
    appId: '1:774263444012:ios:204964d4bf4efef1237789',
    messagingSenderId: '774263444012',
    projectId: 'vanmitra-ai',
    storageBucket: 'vanmitra-ai.firebasestorage.app',
    iosBundleId: 'com.vanmitra.vanmitra_ai',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCHumxWKKMNwi9NCElr6WgIHD40QXbwLSQ',
    appId: '1:774263444012:web:204964d4bf4efef1237789',
    messagingSenderId: '774263444012',
    projectId: 'vanmitra-ai',
    authDomain: 'vanmitra-ai.firebaseapp.com',
    storageBucket: 'vanmitra-ai.firebasestorage.app',
  );
}
