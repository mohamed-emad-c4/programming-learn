abstract class AuthRepository {
  Future<void> register({
    required String name,
    required String nickname,
    required String country,
    required String email,
    required String password,
    required String role,
  });

  Future<String> login({
    required String username,
    required String password,
  });

  Future<void> saveToken(String token); // دالة لتخزين الـ token
  Future<String?> getToken(); // دالة لاسترجاع الـ token
  
 Future<void> clearToken();
  Future<bool> validateToken(String token); // Add this method to the abstract class
 // دالة لحذف الـ token
}