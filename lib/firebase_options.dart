import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCeTkG9y_J4f_eAw9f-s2mtfCWYbIAPK2w',
    authDomain: 'money-7eb69.firebaseapp.com',
    projectId: 'money-7eb69',
    storageBucket: 'money-7eb69.firebasestorage.app',
    messagingSenderId: '609160171719',
    appId: '1:609160171719:web:d0c37479729a30190a6ee2',
  );
}