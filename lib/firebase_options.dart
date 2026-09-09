import 'package:firebase_core/firebase_core.dart';

/// Firebase settings are supplied at build time so project identifiers and API keys
/// are not hardcoded in the repository. Generate the same file with FlutterFire CLI
/// for production if preferred.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    if ([apiKey, appId, messagingSenderId, projectId].any((value) => value.isEmpty)) {
      throw StateError('Firebase configuration is missing. Pass FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID and FIREBASE_PROJECT_ID with --dart-define.');
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
    );
  }
}
