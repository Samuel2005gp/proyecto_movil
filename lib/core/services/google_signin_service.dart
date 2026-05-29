import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'storage_service.dart';

class GoogleSignInService {
  // Web Client ID de Firebase (mismo que en el proyecto web)
  // IMPORTANTE: Este debe ser el Web Client ID COMPLETO de Firebase Console
  // Ve a: Firebase Console > Authentication > Sign-in method > Google > Web SDK configuration
  static const String _webClientId = '5389038456-u7reiubg6mak2h1lthn480b855bpgia0.apps.googleusercontent.com';
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Para Android, el Web Client ID se configura aquí
    serverClientId: _webClientId,
  );

  /// Inicia sesión con Google y retorna los datos del usuario
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('🔵 [Google Auth] Iniciando autenticación con Google...');
      
      // Intentar iniciar sesión
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('❌ [Google Auth] Usuario canceló el inicio de sesión');
        throw Exception('Inicio de sesión cancelado');
      }
      
      print('✅ [Google Auth] Usuario autenticado: ${googleUser.email}');
      
      // Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // El idToken es lo que necesitamos para el backend
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        print('❌ [Google Auth] No se pudo obtener el idToken');
        throw Exception('No se pudo obtener el token de Google');
      }
      
      print('✅ [Google Auth] idToken obtenido correctamente');
      
      // Extraer nombre y apellido del displayName
      final displayName = googleUser.displayName ?? '';
      final nameParts = displayName.split(' ');
      final nombre = nameParts.isNotEmpty ? nameParts[0] : '';
      final apellido = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      // Preparar datos para enviar al backend
      final profile = {
        'nombre': nombre,
        'apellido': apellido,
        'foto': googleUser.photoUrl ?? '',
        'displayName': displayName,
      };
      
      print('👤 [Google Auth] Perfil extraído: $profile');
      print('📤 [Google Auth] Enviando datos al backend...');
      
      // Enviar al backend
      final response = await ApiService.post(
        '/auth/google',
        {
          'idToken': idToken,
          ...profile,
        },
      );
      
      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Error al iniciar sesión con Google';
        print('❌ [Google Auth] Error del backend: $errorMessage');
        throw Exception(errorMessage);
      }
      
      final data = jsonDecode(response.body);
      print('✅ [Google Auth] Respuesta del backend recibida');
      
      // Guardar token y datos del usuario
      final token = data['token'] as String;
      final usuario = data['usuario'] as Map<String, dynamic>;
      
      await StorageService.saveToken(token);
      await StorageService.saveRole(usuario['rol'] ?? 'Cliente');
      await StorageService.saveUserId(usuario['id'] ?? 0);
      await StorageService.saveUserName(usuario['nombre'] ?? 'Usuario');
      
      print('✅ [Google Auth] Datos guardados en storage');
      
      return {
        'token': token,
        'usuario': usuario,
      };
      
    } catch (e) {
      print('❌ [Google Auth] Error: $e');
      rethrow;
    }
  }

  /// Cierra la sesión de Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('✅ [Google Auth] Sesión de Google cerrada');
    } catch (e) {
      print('❌ [Google Auth] Error al cerrar sesión: $e');
    }
  }

  /// Verifica si hay una sesión activa de Google
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Obtiene el usuario actual de Google (si existe)
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }
}
