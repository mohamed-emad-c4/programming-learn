import 'dart:async';
import 'dart:developer';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/repositories/auth_repository_impl.dart';

/// A centralized service to handle authentication across the app
class AuthService {
  // Key constants to standardize token storage
  static const String _tokenKey =
      'access_token'; // Must match auth_repository_impl.dart key
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _tokenGetItInstanceName = 'token';
  static const String _legacyTokenKey =
      'auth_token'; // For backward compatibility

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Repository for auth operations
  final AuthRepositoryImpl _authRepo = AuthRepositoryImpl();

  // Stream controller for auth state changes
  final _authStateController = StreamController<bool>.broadcast();
  Stream<bool> get authStateChanges => _authStateController.stream;

  // Current token cache
  String? _token;

  // Track initialization
  bool _isInitialized = false;

  /// Initialize auth service
  Future<void> init() async {
    if (_isInitialized) return;

    log('Initializing auth service');
    try {
      await _loadToken();
      _isInitialized = true;
      log('Auth service initialized successfully');
    } catch (e) {
      log('Error initializing auth service: $e');
    }
  }

  /// Get the current token
  Future<String?> getToken() async {
    // Return cached token if available
    if (_token != null && _token!.isNotEmpty) {
      log('Using cached token from memory');
      return _token;
    }

    // Otherwise load token
    return await _loadToken();
  }

  /// Load token from storage/GetIt with fallbacks for different sources
  Future<String?> _loadToken() async {
    log('Attempting to load token from multiple sources');

    try {
      // Strategy 1: Check if token is in GetIt
      if (GetIt.I.isRegistered<String>(instanceName: _tokenGetItInstanceName)) {
        _token = GetIt.I<String>(instanceName: _tokenGetItInstanceName);
        log('Token loaded from GetIt');

        // Ensure it's also saved in SharedPreferences for persistence
        await _saveTokenToPrefs(_token!);
        return _token;
      }

      // Strategy 2: Try to get token from SharedPreferences with primary key
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);

      if (_token != null && _token!.isNotEmpty) {
        log('Token loaded from SharedPreferences with primary key');
        _registerTokenInGetIt(_token!);
        return _token;
      }

      // Strategy 3: Try legacy token key
      _token = prefs.getString(_legacyTokenKey);

      if (_token != null && _token!.isNotEmpty) {
        log('Token loaded from SharedPreferences with legacy key');

        // Migrate to standard key
        await prefs.setString(_tokenKey, _token!);
        log('Migrated token from legacy key to standard key');

        _registerTokenInGetIt(_token!);
        return _token;
      }

      // Strategy 4: Try fallback from auth repository
      final repoToken = await _authRepo.getToken();
      if (repoToken != null && repoToken.isNotEmpty) {
        _token = repoToken;
        log('Token loaded from auth repository');

        // Register in GetIt and save to preferences
        _registerTokenInGetIt(_token!);
        await _saveTokenToPrefs(_token!);
        return _token;
      }
    } catch (e) {
      log('Error loading token: $e');
    }

    log('No token found in any storage');
    return null;
  }

  /// Explicitly save a new token from external source (like quiz submission)
  Future<void> saveExternalToken(String token) async {
    log('Saving external token');
    if (token.isEmpty) {
      log('Warning: Attempted to save empty token');
      return;
    }

    _token = token;
    await _saveToken(token);
    log('External token saved successfully');
  }

  /// Login user and store token
  Future<bool> login(String username, String password) async {
    try {
      final token = await _authRepo.login(
        username: username,
        password: password,
      );

      _token = token;
      log('Login successful, token obtained');

      // Save token to all storages
      await _saveToken(token);

      // Notify about auth state change
      _authStateController.add(true);

      return true;
    } catch (e) {
      log('Login failed: $e');
      return false;
    }
  }

  /// Register a new user
  Future<bool> register({
    required String name,
    required String nickname,
    required String country,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _authRepo.register(
        name: name,
        nickname: nickname,
        country: country,
        email: email,
        password: password,
        role: role,
      );
      log('Registration successful');
      return true;
    } catch (e) {
      log('Registration failed: $e');
      return false;
    }
  }

  /// Logout user and clear token
  Future<void> logout() async {
    try {
      await _authRepo.clearToken();

      // Clear token from SharedPreferences (all possible keys)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_legacyTokenKey);
      await prefs.remove(_tokenExpiryKey);

      // Clear from GetIt
      if (GetIt.I.isRegistered<String>(instanceName: _tokenGetItInstanceName)) {
        GetIt.I.unregister<String>(instanceName: _tokenGetItInstanceName);
      }

      // Clear from memory
      _token = null;

      // Notify about auth state change
      _authStateController.add(false);

      log('Logout successful, all tokens cleared');
    } catch (e) {
      log('Logout error: $e');
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      log('No token available, user is not authenticated');
      return false;
    }

    // Verify token validity
    final isValid = await _authRepo.validateToken(token);
    log('Token validation result: $isValid');
    return isValid;
  }

  /// Save token to all storage types
  Future<void> _saveToken(String token) async {
    try {
      // Save to auth repository
      await _authRepo.saveToken(token);

      // Save to SharedPreferences with consistent key
      await _saveTokenToPrefs(token);

      // Register in GetIt
      _registerTokenInGetIt(token);

      log('Token saved to all storage mechanisms');
    } catch (e) {
      log('Error saving token to all storages: $e');
    }
  }

  /// Save token to SharedPreferences
  Future<void> _saveTokenToPrefs(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save to both keys for compatibility
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_legacyTokenKey, token);

      log('Token saved to SharedPreferences (both keys)');
    } catch (e) {
      log('Error saving token to SharedPreferences: $e');
    }
  }

  /// Register token in GetIt
  void _registerTokenInGetIt(String token) {
    try {
      // Check if token already registered
      if (GetIt.I.isRegistered<String>(instanceName: _tokenGetItInstanceName)) {
        // Get the existing token
        final existingToken =
            GetIt.I<String>(instanceName: _tokenGetItInstanceName);

        // If the token is the same, no need to do anything
        if (existingToken == token) {
          log('Token already registered with same value, skipping re-registration');
          return;
        }

        // If the token is different, unregister the old one
        log('Token already registered with different value, updating');
        GetIt.I.unregister<String>(instanceName: _tokenGetItInstanceName);
      }

      // Register the token
      GetIt.I.registerSingleton<String>(token,
          instanceName: _tokenGetItInstanceName);
      log('Token registered in GetIt');
    } catch (e) {
      log('Error registering token in GetIt: $e');

      // Handle specific errors
      if (e.toString().contains('already registered')) {
        log('Token registration conflict detected. This may indicate a race condition.');
        // If we can't unregister, try to use resetLazySingleton instead as a fallback
        try {
          GetIt.I.unregister<String>(
              instanceName: _tokenGetItInstanceName,
              disposingFunction: (token) {});
          GetIt.I.registerSingleton<String>(token,
              instanceName: _tokenGetItInstanceName);
          log('Token re-registered after forceful unregister');
        } catch (innerError) {
          log('Failed to forcefully update token: $innerError');
        }
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
