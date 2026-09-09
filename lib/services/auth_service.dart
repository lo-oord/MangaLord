import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // Configure with --dart-define=GOOGLE_WEB_CLIENT_ID=...; never put a client secret here.
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const oauthRedirectScheme = String.fromEnvironment(
    'GOOGLE_OAUTH_REDIRECT_SCHEME',
    defaultValue: 'com.mangalord.app',
  );
  static const oauthRedirectUri = '$oauthRedirectScheme:/oauthredirect';

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  User? get currentUser {
    try {
      return _auth.currentUser;
    } on FirebaseException {
      // Widget tests may render screens without bootstrapping Firebase.
      return null;
    }
  }
  bool get isAuthenticated => currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> initialize() async {
    // Firebase is initialized by main.dart before this service is used. Reading currentUser
    // restores the persisted native Firebase session without forcing another login.
    await _auth.currentUser?.reload();
  }

  Future<User> signUp({required String username, required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = credential.user!;
    await user.updateDisplayName(username.trim());
    await _writeProfile(user, username: username.trim());
    return user;
  }

  Future<User> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await _writeProfile(credential.user!);
    return credential.user!;
  }

  Future<User> signInWithGoogle() async {
    if (googleWebClientId.isEmpty) {
      throw const AuthConfigurationException('Google OAuth is not configured. Set GOOGLE_WEB_CLIENT_ID.');
    }
    final verifier = _randomUrlSafe(48);
    final challenge = base64Url.encode(sha256.convert(utf8.encode(verifier)).bytes).replaceAll('=', '');
    final state = _randomUrlSafe(24);
    final authorizationUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': googleWebClientId,
      'redirect_uri': oauthRedirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'state': state,
      'access_type': 'offline',
      'prompt': 'select_account',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authorizationUri.toString(),
      callbackUrlScheme: oauthRedirectScheme,
    );
    final callback = Uri.parse(result);
    if (callback.queryParameters['state'] != state) {
      throw const AuthConfigurationException('Invalid OAuth state returned by Google.');
    }
    final error = callback.queryParameters['error'];
    if (error != null) throw AuthCancelledException(error);
    final code = callback.queryParameters['code'];
    if (code == null) throw const AuthConfigurationException('Google did not return an authorization code.');

    final tokenResponse = await http.post(Uri.https('oauth2.googleapis.com', '/token'), body: {
      'client_id': googleWebClientId,
      'code': code,
      'code_verifier': verifier,
      'grant_type': 'authorization_code',
      'redirect_uri': oauthRedirectUri,
    });
    if (tokenResponse.statusCode != 200) {
      throw AuthConfigurationException('Google token exchange failed (${tokenResponse.statusCode}).');
    }
    final token = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final idToken = token['id_token'] as String?;
    if (idToken == null) throw const AuthConfigurationException('Google did not return an ID token.');
    final credential = GoogleAuthProvider.credential(idToken: idToken, accessToken: token['access_token'] as String?);
    final userCredential = await _auth.signInWithCredential(credential);
    await _writeProfile(userCredential.user!);
    return userCredential.user!;
  }

  Future<void> sendReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());
  Future<void> resendVerification() async => await _auth.currentUser?.sendEmailVerification();
  Future<void> reloadUser() async => await _auth.currentUser?.reload();
  Future<void> signOut() => _auth.signOut();

  Future<Map<String, dynamic>> profile() async {
    final user = currentUser;
    if (user == null) return {};
    final snapshot = await _firestore.collection('profiles').doc(user.uid).get();
    return {'uid': user.uid, 'email': user.email, 'displayName': user.displayName, 'photoUrl': user.photoURL, ...?snapshot.data()};
  }

  Future<void> updateProfile({String? username, String? bio}) async {
    final user = currentUser;
    if (user == null) return;
    if (username != null) await user.updateDisplayName(username.trim());
    await _writeProfile(user, username: username, bio: bio);
  }

  Future<void> uploadProfileImage(List<int> bytes, String extension) async {
    final user = currentUser;
    if (user == null) return;
    final ref = _storage.ref('profile_images/${user.uid}.$extension');
    await ref.putData(Uint8List.fromList(bytes), SettableMetadata(contentType: 'image/$extension'));
    final url = await ref.getDownloadURL();
    await user.updatePhotoURL(url);
    await _writeProfile(user, photoUrl: url);
  }

  Future<void> setFavorite(String mangaId, Map<String, dynamic> data) => _upsert('favorites', mangaId, data);
  Future<void> removeFavorite(String mangaId) async {
    final user = currentUser;
    if (user != null) await _firestore.collection('users').doc(user.uid).collection('favorites').doc(_documentId(mangaId)).delete();
  }
  Future<void> setHistory(String mangaId, Map<String, dynamic> data) => _upsert('history', mangaId, data);

  Future<void> _upsert(String collection, String mangaId, Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).collection(collection).doc(_documentId(mangaId)).set({
      ...data,
      'mangaId': mangaId,
      'uid': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getCollection(String name) async {
    final user = currentUser;
    if (user == null) return [];
    final snapshot = await _firestore.collection('users').doc(user.uid).collection(name).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> _writeProfile(User user, {String? username, String? bio, String? photoUrl}) async {
    final values = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'displayName': username ?? user.displayName,
      'photoUrl': photoUrl ?? user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (bio != null) values['bio'] = bio;
    await _firestore.collection('profiles').doc(user.uid).set(values, SetOptions(merge: true));
  }

  String _documentId(String value) => base64Url.encode(utf8.encode(value)).replaceAll('=', '').substring(0, min(80, base64Url.encode(utf8.encode(value)).replaceAll('=', '').length));
  String _randomUrlSafe(int length) {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(length, (_) => random.nextInt(256))).replaceAll('=', '');
  }
}

class AuthCancelledException implements Exception {
  const AuthCancelledException(this.message);
  final String message;
  @override String toString() => message;
}

class AuthConfigurationException implements Exception {
  const AuthConfigurationException(this.message);
  final String message;
  @override String toString() => message;
}
