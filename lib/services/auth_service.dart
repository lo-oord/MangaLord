import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  User? get currentUser => auth.currentUser;
  Stream<User?> get authStateChanges => auth.userChanges();

  Future<UserCredential> signUp({required String username, required String email, required String password}) async {
    final credential = await auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = credential.user!;
    await user.updateDisplayName(username.trim());
    await firestore.collection('users').doc(user.uid).set({'username': username.trim(), 'email': user.email, 'bio': '', 'photoUrl': '', 'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await user.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    final credential = await auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await credential.user?.reload();
    final user = auth.currentUser;
    if (user != null && !user.emailVerified) throw FirebaseAuthException(code: 'email-not-verified', message: 'Please verify your email before signing in.');
    return credential;
  }

  Future<void> sendReset(String email) => auth.sendPasswordResetEmail(email: email.trim());
  Future<void> resendVerification() async { final user = auth.currentUser; if (user != null && !user.emailVerified) await user.sendEmailVerification(); }
  Future<void> reloadUser() async => auth.currentUser?.reload();
  Future<void> signOut() => auth.signOut();

  Future<Map<String, dynamic>> profile() async {
    final uid = currentUser?.uid;
    if (uid == null) return {};
    final snapshot = await firestore.collection('users').doc(uid).get();
    return snapshot.data() ?? {};
  }

  Future<void> updateProfile({String? username, String? bio}) async {
    final user = currentUser;
    if (user == null) return;
    final values = <String, dynamic>{};
    if (username != null) { values['username'] = username.trim(); await user.updateDisplayName(username.trim()); }
    if (bio != null) values['bio'] = bio.trim();
    if (values.isNotEmpty) await firestore.collection('users').doc(user.uid).set(values, SetOptions(merge: true));
  }

  Future<String?> uploadProfileImage(Uint8List bytes, String extension) async {
    final user = currentUser;
    if (user == null) return null;
    final reference = storage.ref('users/${user.uid}/profile.$extension');
    await reference.putData(bytes, SettableMetadata(contentType: 'image/$extension'));
    final url = await reference.getDownloadURL();
    await user.updatePhotoURL(url);
    await firestore.collection('users').doc(user.uid).set({'photoUrl': url}, SetOptions(merge: true));
    return url;
  }

  CollectionReference<Map<String, dynamic>> _subcollection(String name) {
    final uid = currentUser?.uid;
    if (uid == null) throw StateError('Authentication required');
    return firestore.collection('users').doc(uid).collection(name);
  }

  Future<void> setFavorite(String mangaId, Map<String, dynamic> data) => _subcollection('favorites').doc(_safeId(mangaId)).set({...data, 'mangaId': mangaId, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  Future<void> removeFavorite(String mangaId) => _subcollection('favorites').doc(_safeId(mangaId)).delete();
  Future<void> setHistory(String mangaId, Map<String, dynamic> data) => _subcollection('history').doc(_safeId(mangaId)).set({...data, 'mangaId': mangaId, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  Future<List<Map<String, dynamic>>> getCollection(String name) async => (await _subcollection(name).get()).docs.map((doc) => doc.data()).toList();
  String _safeId(String value) => value.replaceAll('/', '_').replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
}
