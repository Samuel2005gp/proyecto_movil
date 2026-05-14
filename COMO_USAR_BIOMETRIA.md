# 🔐 Cómo Usar la Autenticación Biométrica

## Para Usuarios de la App

### 📱 Primera Vez - Configurar Biometría

1. **Inicia sesión** con tu correo y contraseña
2. Después de iniciar sesión exitosamente, verás un mensaje:
   ```
   ¿Deseas habilitar [Huella Digital/Face ID] 
   para iniciar sesión más rápido la próxima vez?
   ```
3. Toca **"Habilitar"** para activar el acceso rápido
4. ¡Listo! La próxima vez podrás usar tu huella o rostro

### 🚀 Iniciar Sesión con Biometría

1. **Abre la app**
2. Verás un mensaje: "Inicio Rápido"
3. Toca **"Usar Biometría"**
4. Coloca tu dedo en el sensor o mira a la cámara
5. ¡Acceso instantáneo!

**Alternativa**: Si prefieres usar contraseña, toca "Usar Contraseña"

### ⚙️ Activar/Desactivar desde el Perfil

#### Para Activar:
1. Ve a tu **Perfil** (icono de usuario)
2. Busca la opción **"Acceso Biométrico"**
3. Activa el **interruptor**
4. Confirma tu identidad con tu huella/rostro
5. Ingresa tu correo y contraseña
6. ¡Listo!

#### Para Desactivar:
1. Ve a tu **Perfil**
2. Busca **"Acceso Biométrico"**
3. Desactiva el **interruptor**
4. Confirma que deseas deshabilitarlo
5. Listo, ahora solo podrás usar contraseña

---

## Para Desarrolladores

### 🛠️ Instalación

```bash
cd proyecto_movil
flutter pub get
flutter run
```

### 📋 Requisitos del Dispositivo

- **Android**: Sensor de huella o reconocimiento facial configurado
- **iOS**: Touch ID o Face ID configurado
- **Versión mínima**: Android 6.0+ / iOS 11.0+

### 🔍 Verificar Implementación

```bash
# Analizar código
flutter analyze --no-fatal-infos

# Ejecutar en dispositivo
flutter run

# Construir APK
flutter build apk --release
```

### 📁 Archivos Clave

```
lib/
├── core/
│   └── services/
│       ├── biometric_service.dart    # Servicio de biometría
│       └── storage_service.dart      # Almacenamiento de credenciales
├── presentation/
│   └── pages/
│       ├── login.dart                # Oferta de configuración
│       └── profile.dart              # Toggle de gestión
└── main.dart                         # Inicio rápido

android/app/src/main/AndroidManifest.xml  # Permisos Android
ios/Runner/Info.plist                      # Permisos iOS
```

### 🧪 Probar en Emulador

**Android Studio:**
```
Settings → Extended Controls → Fingerprint
Touch the sensor
```

**Xcode (iOS Simulator):**
```
Features → Face ID → Enrolled
Features → Face ID → Matching Face
```

### 🔐 Seguridad

**Actual**: Credenciales en `SharedPreferences`  
**Recomendado para producción**: Migrar a `flutter_secure_storage`

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

---

## ❓ Preguntas Frecuentes

### ¿Por qué no veo la opción de biometría?
- Tu dispositivo no tiene sensor de huella o reconocimiento facial
- No has configurado la biometría en tu dispositivo
- Ve a Ajustes → Seguridad → Huella/Face ID

### ¿Qué pasa si cambio mi contraseña?
- Debes deshabilitar y volver a habilitar la biometría
- Ve a Perfil → Acceso Biométrico → Desactivar → Activar

### ¿Es seguro?
- Sí, tus credenciales se guardan localmente en tu dispositivo
- La biometría nunca sale de tu dispositivo
- Siempre se verifica con el servidor antes de guardar

### ¿Puedo usar biometría en varios dispositivos?
- Sí, puedes configurarla en cada dispositivo
- Cada dispositivo guarda sus propias credenciales

### ¿Qué pasa si falla la autenticación?
- Puedes intentar de nuevo
- O usar la opción "Usar Contraseña"
- Después de varios intentos fallidos, el sistema te pedirá usar contraseña

---

## 📞 Soporte

Si tienes problemas:
1. Verifica que tu dispositivo tenga biometría configurada
2. Intenta deshabilitar y volver a habilitar la función
3. Cierra sesión y vuelve a iniciar sesión
4. Contacta al administrador del sistema

---

## 📚 Documentación Completa

- [Guía Técnica Completa](./BIOMETRIC_AUTH_GUIDE.md)
- [Resumen de Implementación](./BIOMETRIC_IMPLEMENTATION_SUMMARY.md)

---

**Versión**: 1.0.0  
**Última actualización**: Mayo 2026  
**Estado**: ✅ Funcional
