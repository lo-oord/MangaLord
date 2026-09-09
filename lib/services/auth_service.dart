import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static const oauthRedirectScheme = String.fromEnvironment(
    'SUPABASE_REDIRECT_SCHEME',
    defaultValue: 'com.mangalord.app',
  );
  static const oauthRedirectUri = '$oauthRedirectScheme://oauthredirect';

  SupabaseClient? _client;
  User? get currentUser => _client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<AuthState> get authStateChanges => _client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<void> initialize() async {
    try {
      _client = Supabase.instance.client;
    } catch (_) {
      // The content browser can still run as a guest when Supabase is not configured.
      _client = null;
    }
  }

  SupabaseClient get _supabase => _client ?? (throw const AuthConfigurationException('Supabase is not configured.'));

  Future<User> signUp({required String username, required String email, required String password}) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': username.trim()},
    );
    final user = response.user;
    if (user == null) throw const AuthConfigurationException('Supabase did not return a user.');
    // With email confirmation enabled Supabase returns a user without a session.
    // RLS correctly prevents writing profiles until the user signs in.
    if (response.session != null) {
      await _writeProfile(user, displayName: username.trim());
    }
    return user;
  }

  Future<User> signIn({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(email: email.trim(), password: password);
    final user = response.user;
    if (user == null) throw const AuthConfigurationException('Supabase did not return a user.');
    await _writeProfile(user);
    return user;
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: oauthRedirectUri,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> sendReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim(), redirectTo: oauthRedirectUri);
  }

  Future<void> resendVerification() async {
    final email = currentUser?.email;
    if (email != null) await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> reloadUser() async {
    final user = currentUser;
    if (user != null) await _writeProfile(user);
  }

  Future<void> signOut() => _supabase.auth.signOut();

  Future<Map<String, dynamic>> profile() async {
    final user = currentUser;
    if (user == null) return {};
    final row = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
    return {
      'uid': user.id,
      'email': user.email,
      'displayName': user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'],
      'photoUrl': user.userMetadata?['avatar_url'],
      ...?row,
    };
  }

  Future<void> updateProfile({String? username, String? bio}) async {
    final user = currentUser;
    if (user == null) return;
    if (username != null) {
      await _supabase.auth.updateUser(UserAttributes(data: {'display_name': username.trim()}));
    }
    await _writeProfile(user, displayName: username, bio: bio);
  }

  Future<void> uploadProfileImage(List<int> bytes, String extension) async {
    final user = currentUser;
    if (user == null) return;
    final path = '${user.id}/avatar.$extension';
    final storage = _supabase.storage.from('profile-images');
    await storage.uploadBinary(path, Uint8List.fromList(bytes), fileOptions: FileOptions(upsert: true, contentType: 'image/$extension'));
    final url = storage.getPublicUrl(path);
    await _supabase.auth.updateUser(UserAttributes(data: {'avatar_url': url}));
    await _writeProfile(user, photoUrl: url);
  }

  Future<void> setFavorite(String mangaId, Map<String, dynamic> data) => _upsert('favorites', mangaId, data);

  Future<void> removeFavorite(String mangaId) async {
    final user = currentUser;
    if (user != null) await _supabase.from('favorites').delete().eq('user_id', user.id).eq('manga_id', mangaId);
  }

  Future<void> setHistory(String mangaId, Map<String, dynamic> data) => _upsert('history', mangaId, data);

  Future<void> _upsert(String table, String mangaId, Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    await _supabase.from(table).upsert({
      'data': data,
      'user_id': user.id,
      'manga_id': mangaId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,manga_id');
  }

  Future<List<Map<String, dynamic>>> getCollection(String table) async {
    final user = currentUser;
    if (user == null) return [];
    final rows = await _supabase.from(table).select().eq('user_id', user.id);
    return (rows as List).map((row) {
      final rowData = Map<String, dynamic>.from(row as Map);
      final data = Map<String, dynamic>.from((rowData['data'] as Map?) ?? {});
      data['mangaId'] = rowData['manga_id'];
      final chapters = data['chapterItems'];
      if (chapters is String) {
        try { data['chapterItems'] = jsonDecode(chapters); } catch (_) {}
      }
      return data;
    }).toList();
  }

  Future<void> _writeProfile(User user, {String? displayName, String? bio, String? photoUrl}) async {
    await _supabase.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': displayName ?? user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'],
      'photo_url': photoUrl ?? user.userMetadata?['avatar_url'],
      if (bio != null) 'bio': bio,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
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
