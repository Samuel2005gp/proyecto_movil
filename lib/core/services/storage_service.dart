import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricEmailKey = 'biometric_email';
  static const String _biometricPasswordKey = 'biometric_password';

  // Guardar token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Guardar rol
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  // Obtener rol
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // Guardar ID de usuario
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  // Obtener ID de usuario
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Guardar nombre de usuario
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Obtener nombre de usuario
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // ── Métodos de Biometría ──────────────────────────────────────────────────

  // Habilitar/deshabilitar autenticación biométrica
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  // Verificar si la biometría está habilitada
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Guardar credenciales para biometría (NOTA: En producción usar flutter_secure_storage)
  static Future<void> saveBiometricCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_biometricEmailKey, email);
    await prefs.setString(_biometricPasswordKey, password);
  }

  // Obtener email guardado para biometría
  static Future<String?> getBiometricEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricEmailKey);
  }

  // Obtener contraseña guardada para biometría
  static Future<String?> getBiometricPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricPasswordKey);
  }

  // Limpiar credenciales biométricas
  static Future<void> clearBiometricCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricEmailKey);
    await prefs.remove(_biometricPasswordKey);
    await prefs.remove(_biometricEnabledKey);
  }

  // ──────────────────────────────────────────────────────────────────────────

  // Limpiar todo (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Guardar preferencias de biometría antes de limpiar
    final biometricEnabled = await isBiometricEnabled();
    final biometricEmail = await getBiometricEmail();
    final biometricPassword = await getBiometricPassword();
    
    await prefs.clear();
    
    // Restaurar preferencias de biometría si estaban habilitadas
    if (biometricEnabled && biometricEmail != null && biometricPassword != null) {
      await setBiometricEnabled(true);
      await saveBiometricCredentials(biometricEmail, biometricPassword);
    }
  }

  // Verificar si hay sesión activa
  static Future<bool> hasActiveSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
