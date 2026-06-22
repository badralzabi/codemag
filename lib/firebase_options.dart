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
        return macos;
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
    apiKey: 'AIzaSyBzzv-JC9JjqBOD-c1XOQXO0Sc4Y1lo1es',
    appId: '1:950548164680:web:1e5edf31eb2a97c692a87d',
    messagingSenderId: '950548164680',
    projectId: 'my-love-f10cc',
    authDomain: 'my-love-f10cc.firebaseapp.com',
    storageBucket: 'my-love-f10cc.firebasestorage.app',
    measurementId: 'G-52C8T6H341',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzzv-JC9JjqBOD-c1XOQXO0Sc4Y1lo1es',
    appId: '1:950548164680:web:1e5edf31eb2a97c692a87d',
    messagingSenderId: '950548164680',
    projectId: 'my-love-f10cc',
    storageBucket: 'my-love-f10cc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzzv-JC9JjqBOD-c1XOQXO0Sc4Y1lo1es',
    appId: '1:950548164680:web:1e5edf31eb2a97c692a87d',
    messagingSenderId: '950548164680',
    projectId: 'my-love-f10cc',
    storageBucket: 'my-love-f10cc.firebasestorage.app',
    iosBundleId: 'com.example.socialMini',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBzzv-JC9JjqBOD-c1XOQXO0Sc4Y1lo1es',
    appId: '1:950548164680:web:1e5edf31eb2a97c692a87d',
    messagingSenderId: '950548164680',
    projectId: 'my-love-f10cc',
    storageBucket: 'my-love-f10cc.firebasestorage.app',
    iosBundleId: 'com.example.socialMini',
  );
}
