// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyDFWhUXiApPxsp4INLkrFaq4iNKhDW4d8M',
    appId: '1:137193838260:web:57b3d956b24d5706ea69e1',
    messagingSenderId: '137193838260',
    projectId: 'chat-room---flutter',
    authDomain: 'chat-room---flutter.firebaseapp.com',
    storageBucket: 'chat-room---flutter.appspot.com',
    measurementId: 'G-WJ95KZ0SEW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHr0yqtLi6KCeDBQTbrOGzRa85IxEgoxU',
    appId: '1:137193838260:android:480b5825285fd39dea69e1',
    messagingSenderId: '137193838260',
    projectId: 'chat-room---flutter',
    storageBucket: 'chat-room---flutter.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCSWONM1tTnjp4jWj8JNgpWBgK_hJCVQ9M',
    appId: '1:137193838260:ios:b65b45f96c8efda4ea69e1',
    messagingSenderId: '137193838260',
    projectId: 'chat-room---flutter',
    storageBucket: 'chat-room---flutter.appspot.com',
    iosBundleId: 'com.example.chatApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCSWONM1tTnjp4jWj8JNgpWBgK_hJCVQ9M',
    appId: '1:137193838260:ios:dbbf31d04e3b5921ea69e1',
    messagingSenderId: '137193838260',
    projectId: 'chat-room---flutter',
    storageBucket: 'chat-room---flutter.appspot.com',
    iosBundleId: 'com.example.chatApp.RunnerTests',
  );
}
