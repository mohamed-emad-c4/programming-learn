import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger.dart';

/// Token manager for securely storing and retrieving auth tokens
class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';

  final AppLogger _logger = AppLogger(tag: 'TokenManager');
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  // In-memory cache for faster access
  String? _cachedToken;
  DateTime? _cachedExpiry;

  // Stream controller for token changes
  final _tokenController = StreamController<String?>.broadcast();

  /// Stream of token changes that can be listened to
  Stream<String?> get tokenStream => _tokenController.stream;

  TokenManager({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _prefs = prefs ?? GetIt.I<SharedPreferences>();

  /// Saves the authentication token securely
  Future<void> saveToken(String token, {DateTime? expiryDate}) async {
    _logger.i('Saving new token');

    // Update in-memory cache
    _cachedToken = token;
    _cachedExpiry = expiryDate;

    // Store token securely
    try {
      await _secureStorage.write(key: _tokenKey, value: token);

      // Register in GetIt for app-wide access
      if (GetIt.I.isRegistered<String>(instanceName: 'token')) {
        GetIt.I.unregister<String>(instanceName: 'token');
      }
      GetIt.I.registerSingleton<String>(token, instanceName: 'token');

      // Store expiry date if provided
      if (expiryDate != null) {
        await _prefs.setString(_tokenExpiryKey, expiryDate.toIso8601String());
      }

      // Notify listeners
      _tokenController.add(token);

      _logger.d('Token saved successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to save token', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieves the current authentication token
  Future<String?> getToken() async {
    // Return cached token if available and not expired
    if (_cachedToken != null) {
      if (_cachedExpiry == null || _cachedExpiry!.isAfter(DateTime.now())) {
        return _cachedToken;
      }
      // Token expired, clear it
      await clearToken();
      return null;
    }

    try {
      // Get token from secure storage
      final token = await _secureStorage.read(key: _tokenKey);

      // Check if token is expired
      final expiryStr = _prefs.getString(_tokenExpiryKey);
      if (token != null && expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (expiry.isBefore(DateTime.now())) {
          _logger.w('Token has expired, clearing');
          await clearToken();
          return null;
        }
        _cachedExpiry = expiry;
      }

      // Cache the token
      _cachedToken = token;

      // Register in GetIt if not null
      if (token != null) {
        if (GetIt.I.isRegistered<String>(instanceName: 'token')) {
          GetIt.I.unregister<String>(instanceName: 'token');
        }
        GetIt.I.registerSingleton<String>(token, instanceName: 'token');
      }

      return token;
    } catch (e, stackTrace) {
      _logger.e('Failed to get token', e, stackTrace);
      return null;
    }
  }

  /// Clears the stored authentication token
  Future<void> clearToken() async {
    _logger.i('Clearing token');

    try {
      // Clear cached values
      _cachedToken = null;
      _cachedExpiry = null;

      // Remove from secure storage
      await _secureStorage.delete(key: _tokenKey);
      await _prefs.remove(_tokenExpiryKey);

      // Unregister from GetIt
      if (GetIt.I.isRegistered<String>(instanceName: 'token')) {
        GetIt.I.unregister<String>(instanceName: 'token');
      }

      // Notify listeners
      _tokenController.add(null);

      _logger.d('Token cleared successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear token', e, stackTrace);
      rethrow;
    }
  }

  /// Checks if the token is valid (not expired)
  Future<bool> isTokenValid() async {
    final token = await getToken();
    return token != null;
  }

  /// Disposes resources
  void dispose() {
    _tokenController.close();
  }
}
