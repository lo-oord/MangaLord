import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static const endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const projectId = '6a9ff222002ab1073f0f';
  static const databaseId = 'MangaLordDB';
  static const favoritesCollectionId = 'Favorites';
  static const historyCollectionId = 'History';
  static const callbackScheme = 'appwrite-callback-6a9ff222002ab1073f0f';

  final Client client = Client()
    ..setEndpoint(endpoint)
    ..setProject(projectId);
  late final Account account = Account(client);
  late final Databases databases = Databases(client);

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    try {
      _currentUser = await account.get();
    } on AppwriteException catch (error) {
      if (error.code != 401) rethrow;
      _currentUser = null;
    }
  }

  Future<bool> ping() async {
    try {
      await client.call(method: HttpMethod.get, path: '/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<User> signUp({required String username, required String email, required String password}) async {
    await account.create(userId: ID.unique(), email: email.trim(), password: password, name: username.trim());
    await account.createEmailPasswordSession(email: email.trim(), password: password);
    _currentUser = await account.get();
    return _currentUser!;
  }

  Future<User> signIn({required String email, required String password}) async {
    await account.createEmailPasswordSession(email: email.trim(), password: password);
    _currentUser = await account.get();
    return _currentUser!;
  }

  Future<void> signInWithGoogle() async {
    await account.createOAuth2Session(
      provider: OAuthProvider.google,
      success: '$callbackScheme://success',
      failure: '$callbackScheme://failure',
    );
    _currentUser = await account.get();
  }

  Future<void> sendReset(String email) => account.createRecovery(email: email.trim(), url: '$callbackScheme://recovery');
  Future<void> resendVerification() => account.createVerification(url: '$callbackScheme://verify');
  Future<void> reloadUser() async => _currentUser = await account.get();
  Future<void> signOut() async { await account.deleteSession(sessionId: 'current'); _currentUser = null; }

  Future<Map<String, dynamic>> profile() async {
    final user = _currentUser ?? await account.get();
    _currentUser = user;
    return Map<String, dynamic>.from(user.prefs.data);
  }

  Future<void> updateProfile({String? username, String? bio}) async {
    final values = <String, dynamic>{...await profile()};
    if (username != null) {
      await account.updateName(name: username.trim());
      values['username'] = username.trim();
    }
    if (bio != null) values['bio'] = bio.trim();
    if (values.isNotEmpty) await account.updatePrefs(prefs: values);
    _currentUser = await account.get();
  }

  Future<void> uploadProfileImage(List<int> bytes, String extension) async {
    throw AppwriteException('Profile image storage is not configured for this project.');
  }

  String _collectionId(String name) => name == 'favorites' ? favoritesCollectionId : historyCollectionId;
  String _documentId(String value) => value.replaceAll('/', '_').replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_').substring(0, value.length > 36 ? 36 : value.length);
  List<String> _permissions(String userId) => [Permission.read(Role.user(userId)), Permission.write(Role.user(userId))];

  Future<void> setFavorite(String mangaId, Map<String, dynamic> data) => _upsert('favorites', mangaId, data);
  Future<void> removeFavorite(String mangaId) async {
    if (_currentUser == null) return;
    try { await databases.deleteDocument(databaseId: databaseId, collectionId: favoritesCollectionId, documentId: _documentId(mangaId)); } on AppwriteException catch (error) { if (error.code != 404) rethrow; }
  }
  Future<void> setHistory(String mangaId, Map<String, dynamic> data) => _upsert('history', mangaId, data);

  Future<void> _upsert(String collection, String mangaId, Map<String, dynamic> data) async {
    final user = _currentUser;
    if (user == null) return;
    final payload = {...data, 'mangaId': mangaId, 'userId': user.$id, 'updatedAt': DateTime.now().toUtc().toIso8601String()};
    if (payload['chapterItems'] is List) payload['chapterItems'] = jsonEncode(payload['chapterItems']);
    final documentId = _documentId(mangaId);
    try {
      await databases.updateDocument(databaseId: databaseId, collectionId: _collectionId(collection), documentId: documentId, data: payload);
    } on AppwriteException catch (error) {
      if (error.code != 404) rethrow;
      await databases.createDocument(databaseId: databaseId, collectionId: _collectionId(collection), documentId: documentId, data: payload, permissions: _permissions(user.$id));
    }
  }

  Future<List<Map<String, dynamic>>> getCollection(String name) async {
    final user = _currentUser;
    if (user == null) return [];
    final result = await databases.listDocuments(databaseId: databaseId, collectionId: _collectionId(name), queries: [Query.equal('userId', user.$id)]);
    return result.documents.map((document) {
      final data = Map<String, dynamic>.from(document.data);
      final chapters = data['chapterItems'];
      if (chapters is String) {
        try { data['chapterItems'] = jsonDecode(chapters); } catch (_) {}
      }
      return data;
    }).toList();
  }
}

class AppwriteAuthException implements Exception {
  const AppwriteAuthException(this.message);
  final String message;
  @override String toString() => message;
}
