# Firebase authentication setup

The app now uses Firebase Authentication, Firestore, and Storage. Appwrite is no longer used by the authentication or cloud-library layer.

## Build configuration

Pass the Firebase Web/Android app values as `--dart-define` values (do not commit secrets):

```bash
flutter pub get
flutter run \\
  --dart-define=FIREBASE_API_KEY=... \\
  --dart-define=FIREBASE_APP_ID=... \\
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \\
  --dart-define=FIREBASE_PROJECT_ID=... \\
  --dart-define=FIREBASE_STORAGE_BUCKET=... \\
  --dart-define=GOOGLE_WEB_CLIENT_ID=... \\
  --dart-define=GOOGLE_OAUTH_REDIRECT_SCHEME=com.mangalord.app
```

The OAuth flow is browser-based: Google Authorization Code + PKCE returns through `com.mangalord.app:/oauthredirect`; the app exchanges the code without a client secret and signs in to Firebase with the Google ID token. Register the exact redirect URI in the Google OAuth client if the client type permits it. If Google Cloud rejects a custom scheme for the existing Web client, use a verified HTTPS App Link or the platform's approved installed-app client; never add a client secret to Flutter.

## Console settings

Enable Email/Password and Google under Firebase Authentication. Add the Android package `com.mangalord.app` and the Firebase app values to the build configuration. Enable Firestore and Storage, deploy `firebase/firestore.rules` and `firebase/storage.rules`, and set the Storage region before first upload. Configure the Google OAuth consent screen and the selected Web client; do not ship its secret.

## Testing

Test registration, sign-in, restart persistence, browser Google sign-in, cancellation/error handling, sign-out, password reset, profile update/photo upload, and favorite/history sync on two installs using the same Firebase account. Confirm every private Firestore document path is under the authenticated UID and that anime, manga, reader, and player screens remain unchanged.
