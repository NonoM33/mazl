import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_service.dart';
import 'push_notification_service.dart';
import 'revenuecat_service.dart';

/// User authentication data
class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final AuthProvider provider;
  final String? accessToken;
  final String? idToken;
  final String? jwtToken; // Backend JWT token

  AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
    this.accessToken,
    this.idToken,
    this.jwtToken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'provider': provider.name,
        'accessToken': accessToken,
        'idToken': idToken,
        'jwtToken': jwtToken,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        provider: AuthProvider.values.firstWhere(
          (e) => e.name == json['provider'],
          orElse: () => AuthProvider.unknown,
        ),
        accessToken: json['accessToken'] as String?,
        idToken: json['idToken'] as String?,
        jwtToken: json['jwtToken'] as String?,
      );

  /// Create a copy with updated JWT token
  AuthUser copyWithJwt(String jwt) => AuthUser(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        provider: provider,
        accessToken: accessToken,
        idToken: idToken,
        jwtToken: jwt,
      );
}

enum AuthProvider {
  google,
  apple,
  email,
  unknown,
}

/// Authentication result
class AuthResult {
  final bool success;
  final AuthUser? user;
  final String? errorMessage;
  final bool isNewUser;

  AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
    this.isNewUser = false,
  });

  factory AuthResult.success(AuthUser user, {bool isNewUser = false}) =>
      AuthResult(success: true, user: user, isNewUser: isNewUser);

  factory AuthResult.failure(String message) =>
      AuthResult(success: false, errorMessage: message);
}

/// Authentication Service handling Google and Apple Sign-In
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final RevenueCatService _revenueCat = RevenueCatService();
  final PushNotificationService _pushService = PushNotificationService();

  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  AuthUser? _currentUser;
  bool _isInitialized = false;

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '114247778518-kpbe9qm21122c1kken6m1d3o23fmtqre.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Current authenticated user
  AuthUser? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Initialize auth service and restore session
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to restore user from secure storage
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson != null) {
        _currentUser = AuthUser.fromJson(jsonDecode(userJson));
        debugPrint('AuthService: Restored user session - ${_currentUser?.email}');

        // Login to RevenueCat and OneSignal with restored user
        if (_currentUser != null) {
          await _revenueCat.login(_currentUser!.id);
          await _pushService.loginUser(int.parse(_currentUser!.id));
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('AuthService: Initialization error - $e');
      _isInitialized = true;
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Sign out first to ensure fresh sign-in
      await _googleSignIn.signOut();

      // Trigger sign-in flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return AuthResult.failure('Google sign-in was cancelled');
      }

      // Get authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        return AuthResult.failure('No ID token received from Google');
      }

      debugPrint('AuthService: Google sign-in successful - ${account.email}');
      debugPrint('AuthService: Sending token to backend...');

      // Send token to backend for verification
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': auth.idToken}),
      );

      if (response.statusCode != 200) {
        debugPrint('AuthService: Backend error - ${response.body}');
        return AuthResult.failure('Backend authentication failed');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        return AuthResult.failure(data['error'] ?? 'Authentication failed');
      }

      // Create auth user with backend data
      final backendUser = data['user'];
      final user = AuthUser(
        id: backendUser['id'].toString(),
        email: backendUser['email'] ?? account.email,
        displayName: backendUser['name'] ?? account.displayName,
        photoUrl: backendUser['picture'] ?? account.photoUrl,
        provider: AuthProvider.google,
        accessToken: auth.accessToken,
        idToken: auth.idToken,
        jwtToken: data['token'],
      );

      // Save user and login to RevenueCat + OneSignal
      await _saveUser(user);
      await _revenueCat.login(user.id);
      await _pushService.loginUser(int.parse(user.id));

      debugPrint('AuthService: Backend auth successful - user ID: ${user.id}');

      return AuthResult.success(user, isNewUser: data['isNewUser'] ?? false);
    } catch (e) {
      debugPrint('AuthService: Google sign-in error - $e');
      return AuthResult.failure('Google sign-in failed: $e');
    }
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    try {
      // Check if Apple Sign-In is available
      if (!Platform.isIOS && !Platform.isMacOS) {
        return AuthResult.failure('Apple Sign-In is only available on iOS and macOS');
      }

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // Request Apple Sign-In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      if (credential.identityToken == null) {
        return AuthResult.failure('No identity token received from Apple');
      }

      // Create display name from Apple credentials
      String? displayName;
      if (credential.givenName != null || credential.familyName != null) {
        displayName = [credential.givenName, credential.familyName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
      }

      debugPrint('AuthService: Apple sign-in successful');
      debugPrint('AuthService: Sending token to backend...');

      // Send token to backend for verification
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/apple'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identityToken': credential.identityToken,
          'fullName': displayName,
          'email': credential.email,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('AuthService: Backend error - ${response.body}');
        return AuthResult.failure('Backend authentication failed');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        return AuthResult.failure(data['error'] ?? 'Authentication failed');
      }

      // Create auth user with backend data
      final backendUser = data['user'];
      final user = AuthUser(
        id: backendUser['id'].toString(),
        email: backendUser['email'] ?? credential.email ?? '',
        displayName: backendUser['name'] ?? displayName,
        photoUrl: backendUser['picture'],
        provider: AuthProvider.apple,
        accessToken: credential.authorizationCode,
        idToken: credential.identityToken,
        jwtToken: data['token'],
      );

      // Save user and login to RevenueCat + OneSignal
      await _saveUser(user);
      await _revenueCat.login(user.id);
      await _pushService.loginUser(int.parse(user.id));

      debugPrint('AuthService: Backend auth successful - user ID: ${user.id}');

      return AuthResult.success(user, isNewUser: data['isNewUser'] ?? false);
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException) {
        if (e.code == AuthorizationErrorCode.canceled) {
          return AuthResult.failure('Apple sign-in was cancelled');
        }
      }
      debugPrint('AuthService: Apple sign-in error - $e');
      return AuthResult.failure('Apple sign-in failed: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      debugPrint('AuthService: Signing in with email - $email');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        debugPrint('AuthService: Login error - ${response.body}');
        return AuthResult.failure(data['error'] ?? 'Email ou mot de passe incorrect');
      }

      if (data['success'] != true) {
        return AuthResult.failure(data['error'] ?? 'Connexion échouée');
      }

      // Create auth user from backend response
      final backendUser = data['user'];
      final user = AuthUser(
        id: backendUser['id'].toString(),
        email: backendUser['email'] ?? email,
        displayName: backendUser['name'],
        photoUrl: backendUser['picture'],
        provider: AuthProvider.email,
        jwtToken: data['token'],
      );

      // Save user and login to RevenueCat + OneSignal
      await _saveUser(user);
      await _revenueCat.login(user.id);
      await _pushService.loginUser(int.parse(user.id));

      debugPrint('AuthService: Email login successful - user ID: ${user.id}');

      return AuthResult.success(user, isNewUser: false);
    } catch (e) {
      debugPrint('AuthService: Email sign-in error - $e');
      return AuthResult.failure('Erreur de connexion: $e');
    }
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      debugPrint('AuthService: Registering with email - $email');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': displayName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('AuthService: Registration error - ${response.body}');
        return AuthResult.failure(data['error'] ?? 'Inscription échouée');
      }

      if (data['success'] != true) {
        return AuthResult.failure(data['error'] ?? 'Inscription échouée');
      }

      // Create auth user from backend response
      final backendUser = data['user'];
      final user = AuthUser(
        id: backendUser['id'].toString(),
        email: backendUser['email'] ?? email,
        displayName: backendUser['name'] ?? displayName,
        photoUrl: backendUser['picture'],
        provider: AuthProvider.email,
        jwtToken: data['token'],
      );

      // Save user and login to RevenueCat + OneSignal
      await _saveUser(user);
      await _revenueCat.login(user.id);
      await _pushService.loginUser(int.parse(user.id));

      debugPrint('AuthService: Email registration successful - user ID: ${user.id}');

      return AuthResult.success(user, isNewUser: true);
    } catch (e) {
      debugPrint('AuthService: Email registration error - $e');
      return AuthResult.failure('Erreur d\'inscription: $e');
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('AuthService: Sending password reset email to - $email');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        debugPrint('AuthService: Password reset error - ${response.body}');
        return AuthResult.failure(data['error'] ?? 'Erreur lors de l\'envoi');
      }

      debugPrint('AuthService: Password reset email sent');

      // Return success without user (no login happens)
      return AuthResult(success: true, isNewUser: false);
    } catch (e) {
      debugPrint('AuthService: Password reset error - $e');
      return AuthResult.failure('Erreur: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Sign out from Google if applicable
      if (_currentUser?.provider == AuthProvider.google) {
        await _googleSignIn.signOut();
      }

      // Logout from RevenueCat and OneSignal
      await _revenueCat.logout();
      await _pushService.logoutUser();

      // Clear stored user data
      await _secureStorage.delete(key: _userKey);
      await _secureStorage.delete(key: _tokenKey);

      _currentUser = null;
      debugPrint('AuthService: User signed out');
    } catch (e) {
      debugPrint('AuthService: Sign out error - $e');
      rethrow;
    }
  }

  /// Delete user account (RGPD compliant)
  Future<AuthResult> deleteAccount({String? reason}) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('Aucun utilisateur connecté');
      }

      debugPrint('AuthService: Deleting account for user ${_currentUser!.id}');

      // Call backend to delete user data
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          if (_currentUser!.jwtToken != null)
            'Authorization': 'Bearer ${_currentUser!.jwtToken}',
        },
        body: jsonEncode({
          'reason': reason ?? 'Non spécifié',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final data = jsonDecode(response.body);
        debugPrint('AuthService: Delete account error - ${response.body}');
        return AuthResult.failure(data['error'] ?? 'Erreur lors de la suppression');
      }

      debugPrint('AuthService: Account deleted on backend');

      // Sign out locally
      await signOut();

      debugPrint('AuthService: Account fully deleted');
      return AuthResult(success: true, isNewUser: false);
    } catch (e) {
      debugPrint('AuthService: Delete account error - $e');
      return AuthResult.failure('Erreur: $e');
    }
  }

  /// Save user to secure storage
  Future<void> _saveUser(AuthUser user) async {
    _currentUser = user;
    await _secureStorage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  /// Generate random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Create SHA256 hash of string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
