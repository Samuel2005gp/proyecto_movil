# Guía de Autenticación Biométrica

## Descripción General

La aplicación móvil ahora soporta autenticación biométrica (huella digital y reconocimiento facial) para un acceso rápido y seguro. Los usuarios pueden habilitar esta función después de iniciar sesión exitosamente.

## Características Implementadas

### 1. **Servicio de Biometría** (`BiometricService`)
- **Ubicación**: `lib/core/services/biometric_service.dart`
- **Funcionalidades**:
  - Verificar si el dispositivo soporta biometría
  - Detectar tipos de biometría disponibles (huella, facial, iris)
  - Autenticar al usuario con mensajes personalizados en español
  - Obtener mensajes amigables según el tipo de biometría

### 2. **Almacenamiento Seguro** (`StorageService`)
- **Ubicación**: `lib/core/services/storage_service.dart`
- **Métodos agregados**:
  - `setBiometricEnabled(bool)` - Habilitar/deshabilitar biometría
  - `isBiometricEnabled()` - Verificar si está habilitada
  - `saveBiometricCredentials(email, password)` - Guardar credenciales
  - `getBiometricEmail()` / `getBiometricPassword()` - Recuperar credenciales
  - `clearBiometricCredentials()` - Limpiar credenciales guardadas
- **Nota**: Las preferencias biométricas se preservan al cerrar sesión

### 3. **Inicio Automático con Biometría** (`main.dart`)
- **Ubicación**: `lib/main.dart`
- **Flujo**:
  1. Al iniciar la app, verifica si hay sesión activa
  2. Si la biometría está habilitada y disponible, muestra diálogo
  3. Usuario puede elegir entre biometría o login manual
  4. Autenticación biométrica → login automático con credenciales guardadas

### 4. **Configuración en Login** (`login.dart`)
- **Ubicación**: `lib/presentation/pages/login.dart`
- **Flujo**:
  1. Usuario inicia sesión exitosamente
  2. Si la biometría no está configurada y el dispositivo la soporta:
     - Muestra diálogo ofreciendo habilitar la función
     - Usuario puede aceptar o rechazar
  3. Si acepta, guarda credenciales y habilita biometría
  4. Navega a la pantalla principal

### 5. **Gestión en Perfil** (`profile.dart`)
- **Ubicación**: `lib/presentation/pages/profile.dart`
- **Funcionalidades**:
  - Toggle para habilitar/deshabilitar biometría
  - Solo visible si el dispositivo soporta biometría
  - **Para habilitar**:
    1. Solicita autenticación biométrica para confirmar identidad
    2. Pide credenciales (email y contraseña)
    3. Verifica credenciales con el servidor
    4. Guarda y habilita si son correctas
  - **Para deshabilitar**:
    1. Solicita confirmación
    2. Limpia credenciales guardadas
    3. Deshabilita la función

## Permisos de Plataforma

### Android
**Archivo**: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### iOS
**Archivo**: `ios/Runner/Info.plist`
```xml
<key>NSFaceIDUsageDescription</key>
<string>Necesitamos acceso a Face ID para autenticación rápida y segura</string>
```

## Dependencias

**Archivo**: `pubspec.yaml`
```yaml
dependencies:
  local_auth: ^2.3.0
  local_auth_android: ^1.0.47
  local_auth_ios: ^1.2.1
```

## Flujos de Usuario

### Flujo 1: Primera Configuración
1. Usuario inicia sesión por primera vez
2. Sistema detecta que el dispositivo soporta biometría
3. Muestra diálogo: "¿Deseas habilitar [Huella Digital/Face ID]?"
4. Si acepta:
   - Guarda credenciales de forma segura
   - Habilita autenticación biométrica
   - Muestra confirmación
5. Navega a pantalla principal

### Flujo 2: Inicio con Biometría
1. Usuario abre la app
2. Sistema detecta sesión activa y biometría habilitada
3. Muestra diálogo con opciones:
   - "Usar [Huella Digital/Face ID]"
   - "Iniciar sesión manualmente"
4. Si elige biometría:
   - Solicita autenticación biométrica
   - Si es exitosa, inicia sesión automáticamente
   - Navega a pantalla principal según rol
5. Si elige manual o falla:
   - Muestra pantalla de login

### Flujo 3: Gestión desde Perfil
1. Usuario navega a su perfil
2. Ve toggle "Acceso Biométrico" (solo si dispositivo lo soporta)
3. **Para habilitar**:
   - Activa el toggle
   - Sistema solicita autenticación biométrica
   - Muestra diálogo para ingresar credenciales
   - Verifica credenciales con servidor
   - Habilita si son correctas
4. **Para deshabilitar**:
   - Desactiva el toggle
   - Sistema solicita confirmación
   - Limpia credenciales y deshabilita

## Seguridad

### Consideraciones Actuales
- **Almacenamiento**: Actualmente usa `SharedPreferences` para guardar credenciales
- **Encriptación**: Las credenciales se guardan en texto plano localmente
- **Validación**: Siempre verifica credenciales con el servidor antes de habilitar

### Recomendaciones para Producción
⚠️ **IMPORTANTE**: Para un entorno de producción, se recomienda:

1. **Migrar a `flutter_secure_storage`**:
   ```yaml
   dependencies:
     flutter_secure_storage: ^9.0.0
   ```
   - Proporciona encriptación nativa por plataforma
   - Usa Keychain en iOS y Keystore en Android
   - Protege credenciales contra acceso no autorizado

2. **Implementar tokens de refresh**:
   - No guardar contraseñas, solo tokens de refresh
   - Renovar tokens automáticamente
   - Reducir riesgo de exposición de credenciales

3. **Agregar timeout de sesión**:
   - Invalidar sesión biométrica después de X días
   - Requerir login manual periódicamente

4. **Logging y auditoría**:
   - Registrar intentos de autenticación biométrica
   - Alertar sobre múltiples fallos

## Pruebas

### Dispositivos Físicos
- ✅ **Recomendado**: Probar en dispositivos físicos reales
- ⚠️ **Emuladores**: La biometría tiene soporte limitado en emuladores

### Android (Emulador)
```bash
# Habilitar huella en emulador
adb -e emu finger touch <finger_id>
```

### iOS (Simulador)
- Features → Face ID / Touch ID → Enrolled
- Features → Face ID / Touch ID → Matching Face/Touch

### Casos de Prueba
1. ✅ Dispositivo sin biometría configurada
2. ✅ Dispositivo con biometría configurada
3. ✅ Habilitar biometría después de login
4. ✅ Inicio con biometría exitoso
5. ✅ Inicio con biometría fallido
6. ✅ Deshabilitar biometría desde perfil
7. ✅ Credenciales incorrectas al habilitar
8. ✅ Cerrar sesión preserva preferencias
9. ✅ Múltiples usuarios en mismo dispositivo

## Mensajes de Usuario

Todos los mensajes están en español:

- **Huella Digital**: "Coloca tu dedo en el sensor"
- **Face ID**: "Mira a la cámara para autenticarte"
- **Reconocimiento Facial**: "Mira a la cámara para autenticarte"
- **Reconocimiento de Iris**: "Mira a la cámara para escanear tu iris"
- **Biometría Genérica**: "Autentícate para continuar"

## Solución de Problemas

### Problema: Biometría no disponible
**Causa**: Dispositivo no soporta o no tiene biometría configurada
**Solución**: La opción no se muestra, usuario usa login tradicional

### Problema: Autenticación falla constantemente
**Causa**: Sensor sucio, dedo/cara no registrado correctamente
**Solución**: Usuario puede elegir "Iniciar sesión manualmente"

### Problema: Credenciales guardadas inválidas
**Causa**: Usuario cambió contraseña desde web
**Solución**: Sistema detecta error 401, solicita login manual y limpia credenciales

### Problema: App crashea al usar biometría
**Causa**: Permisos no configurados correctamente
**Solución**: Verificar permisos en AndroidManifest.xml e Info.plist

## Próximos Pasos (Opcional)

1. ✅ Implementar `flutter_secure_storage` para producción
2. ✅ Agregar analytics para medir adopción de biometría
3. ✅ Implementar sistema de tokens de refresh
4. ✅ Agregar opción de "Recordar dispositivo" (30 días)
5. ✅ Soporte para múltiples cuentas en mismo dispositivo
6. ✅ Notificaciones de seguridad (nuevo dispositivo, cambio de contraseña)

## Recursos Adicionales

- [local_auth Package](https://pub.dev/packages/local_auth)
- [Android Biometric API](https://developer.android.com/training/sign-in/biometric-auth)
- [iOS Local Authentication](https://developer.apple.com/documentation/localauthentication)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)

---

**Última actualización**: Mayo 2026
**Versión**: 1.0.0
**Estado**: ✅ Implementado y funcional
