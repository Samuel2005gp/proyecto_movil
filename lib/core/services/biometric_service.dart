import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica si el dispositivo soporta autenticación biométrica
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      // Error verificando soporte biométrico
      return false;
    }
  }

  /// Verifica si hay biometría configurada en el dispositivo
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      // Error verificando biometría disponible
      return false;
    }
  }

  /// Obtiene la lista de biometrías disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      // Error obteniendo biometrías disponibles
      return [];
    }
  }

  /// Autentica al usuario usando biometría
  static Future<bool> authenticate({
    String localizedReason = 'Por favor autentícate para continuar',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Verificar si el dispositivo soporta biometría
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return false;
      }

      // Verificar si hay biometría configurada
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return false;
      }

      // Obtener biometrías disponibles
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return false;
      }

      // Autenticar
      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticación Biométrica',
            cancelButton: 'Cancelar',
            biometricHint: 'Verifica tu identidad',
            biometricNotRecognized: 'No reconocido. Intenta de nuevo',
            biometricSuccess: 'Autenticación exitosa',
            deviceCredentialsRequiredTitle: 'Autenticación requerida',
            deviceCredentialsSetupDescription: 'Configura la autenticación biométrica',
            goToSettingsButton: 'Ir a configuración',
            goToSettingsDescription: 'La autenticación biométrica no está configurada',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
            goToSettingsButton: 'Ir a configuración',
            goToSettingsDescription: 'La autenticación biométrica no está configurada',
            lockOut: 'Por favor habilita Face ID/Touch ID',
          ),
        ],
      );

      return authenticated;
    } on PlatformException catch (e) {
      // Manejar errores específicos de la plataforma
      // Los errores se manejan silenciosamente en producción
      return false;
    } catch (e) {
      // Error inesperado en autenticación biométrica
      return false;
    }
  }

  /// Obtiene un mensaje descriptivo del tipo de biometría disponible
  static Future<String> getBiometricTypeMessage() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return 'No hay biometría disponible';
      }

      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Reconocimiento Facial';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Huella Digital';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        return 'Reconocimiento de Iris';
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        return 'Autenticación Biométrica Fuerte';
      } else if (availableBiometrics.contains(BiometricType.weak)) {
        return 'Autenticación Biométrica';
      }

      return 'Biometría Disponible';
    } catch (e) {
      return 'Biometría';
    }
  }

  /// Verifica si la biometría está disponible y configurada
  static Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await isDeviceSupported();
      final canCheck = await canCheckBiometrics();
      final availableBiometrics = await getAvailableBiometrics();
      
      return isSupported && canCheck && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
