import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../cache/api_snapshots.dart';
import '../images/photo_cache.dart';
import '../dev/dev_login.dart';
import 'couple_service.dart';
import 'apple/apple_web_sign_in.dart';
import 'google/google_client_ids.dart';
import '../dev/dev_session.dart';
import 'api_service.dart';
import 'profile_completeness_service.dart';
import 'push_notification_service.dart';
import 'session_end.dart';
import 'session_guard.dart';
import 'store/store_session.dart';

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

  /// The App Store review account, signed in with an identifier and a password.
  review,
  unknown,
}

/// Why a sign-in or account call did not succeed. The screen writes
/// the sentence in the member's language; the server's own text is never
/// shown.
enum AuthFailure {
  cancelled,
  rateLimited,

  /// The identifier or the password was refused (never which one).
  invalidCredentials,
  network,
  server,
  unsupported,
  notSignedIn,
  unknown,
}

/// The failure behind an HTTP [status] refused by the auth endpoints.
AuthFailure authFailureForStatus(int status) {
  if (status == 429) return AuthFailure.rateLimited;
  if (status >= 500) return AuthFailure.server;
  return AuthFailure.unknown;
}

/// The failure behind an exception thrown while calling the server.
AuthFailure authFailureOf(Object error) =>
    error is SocketException || error is http.ClientException || error is TimeoutException
        ? AuthFailure.network
        : AuthFailure.unknown;

/// Authentication result
class AuthResult {
  final bool success;
  final AuthUser? user;

  /// Why it failed; null on success.
  final AuthFailure? failure;

  AuthResult({
    required this.success,
    this.user,
    this.failure,
  });

  /// A diagnostic for the logs, never a sentence for the member: screens
  /// read [failure]. Kept so that screens not yet migrated still compile.
  String? get errorMessage => failure?.name;

  factory AuthResult.success(AuthUser user) =>
      AuthResult(success: true, user: user);

  factory AuthResult.failure(AuthFailure failure) =>
      AuthResult(success: false, failure: failure);
}

/// Authentication Service handling Google and Apple Sign-In, plus the one
/// identifier + password sign-in of the App Store review account (v1: no
/// e-mail sign-in, the server has no such route)
class AuthService extends ChangeNotifier {
  static AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() : _pushService = PushNotificationService();

  /// An instance with its own push service, for tests that must observe the
  /// sign-out without the push server.
  @visibleForTesting
  AuthService.forTesting({required PushNotificationService push})
    : _pushService = push;

  /// Replaces the singleton; the next `AuthService()` returns [service].
  @visibleForTesting
  static set instanceForTesting(AuthService service) => _instance = service;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final StoreSession _store = StoreSession();
  final PushNotificationService _pushService;
  final ProfileCompletenessService _profileCompleteness = ProfileCompletenessService();

  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  AuthUser? _currentUser;
  bool _isInitialized = false;
  SessionEndReason? _sessionEndReason;
  bool _endingSession = false;

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: googleClientIdsFor(defaultTargetPlatform).clientId,
    serverClientId: googleClientIdsFor(defaultTargetPlatform).serverClientId,
    scopes: ['email', 'profile'],
  );

  /// Current authenticated user
  AuthUser? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Why the app signed the member out by itself (expired token, disabled
  /// account), until the next sign-in. `null` while signed in, and after a
  /// sign-out the member chose.
  SessionEndReason? get sessionEndReason => _sessionEndReason;

  /// Initialize auth service and restore session
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to restore user from secure storage
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson != null) {
        _currentUser = AuthUser.fromJson(jsonDecode(userJson));
        debugPrint('AuthService: Restored user session - ${_currentUser?.email}');

        // Relit l'abonnement et déclare l’appareil au serveur de push pour l’utilisateur restauré
        if (_currentUser != null) {
          unawaited(_store.onSignedIn(_currentUser!.jwtToken));
          await _pushService.loginUser(int.parse(_currentUser!.id));
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('AuthService: Initialization error - $e');
      _isInitialized = true;
    }
    notifyListeners();
  }

  /// Connexion fictive, réservée au développement local.
  ///
  /// Session purement en mémoire : pas de JWT, aucun appel au vrai serveur,
  /// rien d'écrit en stockage sécurisé, ni abonnement ni notifications push.
  /// Les requêtes sont servies par `DemoHttpClient` tant que la session dure.
  Future<AuthResult> signInAsDemo() async {
    if (!kDevLoginAvailable) {
      throw StateError('La connexion fictive est réservée au mode debug.');
    }
    final user = AuthUser(
      id: '0',
      email: 'demo@example.com',
      displayName: 'Léa (démo)',
      provider: AuthProvider.email,
    );
    DevSession.start();
    _sessionEndReason = null;
    _profileCompleteness.reset();
    // A demo session always starts empty: drop the couple cached by a previous
    // run, or the first sync would announce « Le mode couple a pris fin ».
    await CoupleService().reset();
    _currentUser = user;
    debugPrint('AuthService: session fictive démarrée');
    // Le solde de Boosts et de Super Likes fictif, servi par DemoHttpClient.
    unawaited(_store.onDemoSignedIn());
    notifyListeners();
    return AuthResult.success(user);
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Sign out first to ensure fresh sign-in
      await _googleSignIn.signOut();

      // Trigger sign-in flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return AuthResult.failure(AuthFailure.cancelled);
      }

      // Get authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        return AuthResult.failure(AuthFailure.unknown);
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
        return AuthResult.failure(authFailureForStatus(response.statusCode));
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        return AuthResult.failure(AuthFailure.unknown);
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

      await _openSession(user);
      return AuthResult.success(user);
    } catch (e) {
      debugPrint('AuthService: Google sign-in error - $e');
      return AuthResult.failure(authFailureOf(e));
    }
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    try {
      // Natif sur iOS et macOS ; ailleurs, par la page web d'Apple.
      final webOptions = appleWebAuthenticationOptions(
        platform: defaultTargetPlatform,
      );
      if (!Platform.isIOS && !Platform.isMacOS && webOptions == null) {
        return AuthResult.failure(AuthFailure.unsupported);
      }

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final webState = webOptions == null ? null : _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // Request Apple Sign-In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        webAuthenticationOptions: webOptions,
        state: webState,
      );

      // Par le web, la réponse revient par un lien que n'importe quelle page
      // peut ouvrir : seule celle qui porte notre `state` est la nôtre.
      if (!appleWebAnswerIsOurs(sent: webState, received: credential.state)) {
        return AuthResult.failure(AuthFailure.unknown);
      }

      return await signInWithAppleCredential(credential);
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException) {
        if (e.code == AuthorizationErrorCode.canceled) {
          return AuthResult.failure(AuthFailure.cancelled);
        }
      }
      debugPrint('AuthService: Apple sign-in error - $e');
      return AuthResult.failure(authFailureOf(e));
    }
  }

  /// Sends what Apple gave to the backend and opens the session. The
  /// authorization code goes along with the identity token: the server
  /// exchanges it for a refresh token, which it must revoke when the account
  /// is deleted (App Store rule 5.1.1(v)).
  @visibleForTesting
  Future<AuthResult> signInWithAppleCredential(
    AuthorizationCredentialAppleID credential,
  ) async {
    try {
      if (credential.identityToken == null) {
        return AuthResult.failure(AuthFailure.unknown);
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
          'authorizationCode': credential.authorizationCode,
          'fullName': displayName,
          'email': credential.email,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('AuthService: Backend error - ${response.body}');
        return AuthResult.failure(authFailureForStatus(response.statusCode));
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        return AuthResult.failure(AuthFailure.unknown);
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

      await _openSession(user);
      return AuthResult.success(user);
    } catch (e) {
      debugPrint('AuthService: Apple sign-in error - $e');
      return AuthResult.failure(authFailureOf(e));
    }
  }

  /// Signs in the App Store review account with an identifier and a password
  /// (docs/launch/REVIEW-LOGIN-CONTRAT.md). The session opens like the Apple
  /// one. The password goes to the server and nowhere else: it is neither
  /// logged nor stored, and no error text is printed (an exception may quote
  /// the request body).
  Future<AuthResult> signInWithReviewCredentials(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode != 200) {
        debugPrint('AuthService: review sign-in refused (${response.statusCode})');
        return AuthResult.failure(_reviewFailureForStatus(response.statusCode));
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return AuthResult.failure(AuthFailure.unknown);
      }

      final backendUser = data['user'];
      final user = AuthUser(
        id: backendUser['id'].toString(),
        email: backendUser['email'] ?? '',
        displayName: backendUser['name'],
        photoUrl: backendUser['picture'],
        provider: AuthProvider.review,
        jwtToken: data['token'],
      );

      await _openSession(user);
      return AuthResult.success(user);
    } catch (e) {
      debugPrint('AuthService: review sign-in error - ${e.runtimeType}');
      return AuthResult.failure(authFailureOf(e));
    }
  }

  static AuthFailure _reviewFailureForStatus(int status) =>
      status == 401 ? AuthFailure.invalidCredentials : authFailureForStatus(status);

  /// Saves the user, reads the subscription again (without holding the
  /// sign-in back), registers the device with the push server and asks
  /// whether the profile is complete.
  Future<void> _openSession(AuthUser user) async {
    await _saveUser(user);
    unawaited(_store.onSignedIn(user.jwtToken));
    await _pushService.loginUser(int.parse(user.id));

    debugPrint('AuthService: Backend auth successful - user ID: ${user.id}');

    await _loadProfileCompleteness();
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (DevSession.isActive) {
      // Session fictive : rien à révoquer côté push / stockage, mais le solde
      // fictif et son jeton ne doivent pas survivre à la démo.
      _store.onSignedOut();
      DevSession.stop();
      _profileCompleteness.reset();
      _currentUser = null;
      unawaited(_forgetCachedData());
      debugPrint('AuthService: session fictive terminée');
      notifyListeners();
      return;
    }
    try {
      // Sign out from Google if applicable
      if (_currentUser?.provider == AuthProvider.google) {
        await _googleSignIn.signOut();
      }

      // Efface l'abonnement et le solde en mémoire et retire l’appareil du serveur de push
      _store.onSignedOut();
      await _pushService.logoutUser();

      // Clear stored user data
      await _secureStorage.delete(key: _userKey);
      await _secureStorage.delete(key: _tokenKey);

      DevSession.stop();
      _profileCompleteness.reset();
      _currentUser = null;
      await _forgetCachedData();
      debugPrint('AuthService: User signed out');
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService: Sign out error - $e');
      rethrow;
    }
  }

  /// Nothing seen by the member who leaves may be shown to the next one: the
  /// kept answers (memory and disk) and the photos go.
  Future<void> _forgetCachedData() async {
    await ApiSnapshots.instance.clear();
    await MazlPhotoCache.clear();
  }

  /// Ends the session because the server (HTTP 401, 403 `account_disabled`) or
  /// the socket (close 4001, 4003) says it is over: the same sign-out as the
  /// settings', and the router brings back the login screen.
  ///
  /// Safe to call from every request that fails at once: only the first call
  /// signs out. [requestToken] is the token the failed request carried; an
  /// answer to a previous session leaves the current one alone.
  Future<void> endSession(
    SessionEndReason reason, {
    String? requestToken,
  }) async {
    final user = _currentUser;
    if (user == null || _endingSession || DevSession.isActive) return;
    if (requestToken != null && requestToken != user.jwtToken) return;
    _endingSession = true;
    _sessionEndReason = reason;
    try {
      await signOut();
    } catch (e) {
      // The session is over whatever the cleanup said: do not stay in it.
      debugPrint('AuthService: sign-out after the session ended failed - $e');
      _currentUser = null;
      notifyListeners();
    } finally {
      _endingSession = false;
    }
  }

  /// Delete user account (RGPD compliant)
  Future<AuthResult> deleteAccount({String? reason}) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure(AuthFailure.notSignedIn);
      }

      debugPrint('AuthService: Deleting account for user ${_currentUser!.id}');

      // Call backend to delete user data
      final client = SessionGuardClient();
      final http.Response response;
      try {
        response = await client.delete(
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
      } finally {
        client.close();
      }

      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint('AuthService: Delete account error - ${response.body}');
        return AuthResult.failure(authFailureForStatus(response.statusCode));
      }

      debugPrint('AuthService: Account deleted on backend');

      // Sign out locally
      await signOut();

      debugPrint('AuthService: Account fully deleted');
      return AuthResult(success: true);
    } catch (e) {
      debugPrint('AuthService: Delete account error - $e');
      return AuthResult.failure(authFailureOf(e));
    }
  }

  /// Asks the backend whether the member has given gender and looking-for, so
  /// the router already knows when the first screen opens. A failure leaves it
  /// unknown; Discover then answers 409 and the router reacts.
  Future<void> _loadProfileCompleteness() => _profileCompleteness.refresh();

  /// Opens a session without the network, for tests.
  @visibleForTesting
  Future<void> debugSignIn(AuthUser user) => _saveUser(user);

  /// Save user to secure storage
  Future<void> _saveUser(AuthUser user) async {
    // A new account must not inherit the previous one's answer.
    _profileCompleteness.reset();
    _sessionEndReason = null;
    // Another account than the one whose answers are kept: they are dropped.
    await ApiSnapshots.instance.bindOwner(user.id);
    _currentUser = user;
    await _secureStorage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
    notifyListeners();
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
