import 'dart:async';
import 'dart:developer';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/repositories/auth_repository_impl.dart';

/// A centralized service to handle authentication across the app
class AuthService {
  // Key constants to standardize token storage
  static const String _tokenKey = 'access_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _tokenGetItInstanceName = 'token';

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

  /// Initialize auth service
  Future<void> init() async {
    log('Initializing auth service');
    await _loadToken();
  }

  /// Get the current token
  Future<String?> getToken() async {
    // Return cached token if available
    if (_token != null) {
      return _token;
    }

    // Otherwise load token
    return await _loadToken();
  }

  /// Load token from storage/GetIt
  Future<String?> _loadToken() async {
    // Check if token is in GetIt
    if (GetIt.I.isRegistered<String>(instanceName: _tokenGetItInstanceName)) {
      _token = GetIt.I<String>(instanceName: _tokenGetItInstanceName);
      log('Token loaded from GetIt');
      return _token;
    }

    try {
      // Try to get token from SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);

      if (_token != null && _token!.isNotEmpty) {
        log('Token loaded from SharedPreferences');

        // Register in GetIt
        _registerTokenInGetIt(_token!);
        return _token;
      }

      // Try fallback from auth repository
      final repoToken = await _authRepo.getToken();
      if (repoToken != null && repoToken.isNotEmpty) {
        _token = repoToken;
        log('Token loaded from auth repository');

        // Register in GetIt
        _registerTokenInGetIt(_token!);

        // Save with consistent key
        await _saveTokenToPrefs(_token!);
        return _token;
      }
    } catch (e) {
      log('Error loading token: $e');
    }

    log('No token found');
    return null;
  }

  /// Login user and store token
  Future<bool> login(String username, String password) async {
    try {
      final token = await _authRepo.login(
        username: username,
        password: password,
      );

      _token = token;
      log('Login successful');

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

      // Clear token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenExpiryKey);

      // Clear from GetIt
      if (GetIt.I.isRegistered<String>(instanceName: _tokenGetItInstanceName)) {
        GetIt.I.unregister<String>(instanceName: _tokenGetItInstanceName);
      }

      // Clear from memory
      _token = null;

      // Notify about auth state change
      _authStateController.add(false);

      log('Logout successful');
    } catch (e) {
      log('Logout error: $e');
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    // Verify token validity
    return await _authRepo.validateToken(token);
  }

  /// Save token to all storage types
  Future<void> _saveToken(String token) async {
    // Save to auth repository
    await _authRepo.saveToken(token);

    // Save to SharedPreferences with consistent key
    await _saveTokenToPrefs(token);

    // Register in GetIt
    _registerTokenInGetIt(token);
  }

  /// Save token to SharedPreferences
  Future<void> _saveTokenToPrefs(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      log('Token saved to SharedPreferences');
    } catch (e) {
      log('Error saving token to SharedPreferences: $e');
    }
  }

  /// Register token in GetIt
  void _registerTokenInGetIt(String token) {
    try {
      if (GetIt.I.isRegistered<String>(instanceName: _tokenGetItInstanceName)) {
        GetIt.I.unregister<String>(instanceName: _tokenGetItInstanceName);
      }
      GetIt.I.registerSingleton<String>(token,
          instanceName: _tokenGetItInstanceName);
      log('Token registered in GetIt');
    } catch (e) {
      log('Error registering token in GetIt: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
