# 🐛 Instrucciones para Depurar Biometría

## Problema Actual
El diálogo de "Inicio Rápido" aparece, pero al tocar "Usar Biometría" no funciona.

## Pasos para Depurar

### 1. Reconstruir la App con Logs
```bash
cd proyecto_movil
flutter run
```

### 2. Observar los Logs
Cuando ejecutes la app, verás logs en la consola que te dirán exactamente qué está pasando:

```
🔐 _offerBiometricSetup iniciado
🔐 Biometría ya habilitada: false
🔐 Biometría disponible en dispositivo: true
🔐 Tipo de biometría: Huella Digital
🔐 Usuario eligió habilitar: true
🔐 Guardando credenciales: usuario@ejemplo.com
🔐 Credenciales guardadas - Email: ✅, Password: ✅
```

### 3. Verificar Flujo Completo

#### Paso A: Primera vez (Habilitar biometría)
1. Desinstala la app completamente
2. Instala de nuevo: `flutter run`
3. Inicia sesión con correo y contraseña
4. Cuando aparezca el diálogo "¿Deseas habilitar...?", toca **"Habilitar"**
5. **OBSERVA LOS LOGS** en la consola

#### Paso B: Segunda vez (Usar biometría)
1. Cierra la app completamente (no solo minimizar)
2. Abre la app de nuevo
3. Debe aparecer el diálogo "Inicio Rápido"
4. Toca **"Usar Biometría"**
5. **OBSERVA LOS LOGS** en la consola

### 4. Logs Esperados al Usar Biometría

```
🔐 Iniciando autenticación biométrica...
🔐 Resultado de autenticación: true
🔐 Obteniendo credenciales guardadas...
🔐 Email guardado: ✅ Sí
🔐 Password guardado: ✅ Sí
🔐 Intentando login con credenciales guardadas...
🔐 Intentando login con: usuario@ejemplo.com
🔐 Respuesta del servidor: 200
✅ Login exitoso - Rol: Admin, Usuario: Samuel Gonzalez
```

### 5. Posibles Problemas y Soluciones

#### Problema 1: "No se encontraron credenciales guardadas"
**Logs**:
```
🔐 Email guardado: ❌ No
🔐 Password guardado: ❌ No
```

**Solución**:
- Las credenciales no se guardaron en el primer login
- Desinstala la app
- Vuelve a instalar
- Asegúrate de tocar "Habilitar" cuando aparezca el diálogo

#### Problema 2: "Autenticación biométrica cancelada"
**Logs**:
```
🔐 Resultado de autenticación: false
❌ Autenticación biométrica cancelada o fallida
```

**Solución**:
- El sensor biométrico no reconoció tu huella/rostro
- Intenta de nuevo
- Verifica que tu huella esté registrada en el dispositivo

#### Problema 3: "Credenciales inválidas"
**Logs**:
```
🔐 Respuesta del servidor: 401
❌ Credenciales inválidas - Status: 401
```

**Solución**:
- Las credenciales guardadas son incorrectas
- Cambiaste la contraseña desde la web
- Ve a Perfil → Desactiva biometría → Vuelve a activarla

#### Problema 4: "Error de conexión"
**Logs**:
```
❌ Error en login: SocketException: Failed host lookup
```

**Solución**:
- No hay conexión a internet
- El servidor backend no está corriendo
- Verifica la URL del API en `.env`

### 6. Comandos Útiles

#### Ver logs en tiempo real (Android)
```bash
flutter run
# O si ya está corriendo:
adb logcat | grep "🔐"
```

#### Ver logs en tiempo real (iOS)
```bash
flutter run
# Los logs aparecerán en la consola de Xcode
```

#### Limpiar datos de la app (Android)
```bash
adb shell pm clear com.example.proyecto_mobil
```

#### Reinstalar app
```bash
flutter clean
flutter pub get
flutter run
```

### 7. Verificar Estado de Biometría Manualmente

Puedes agregar un botón temporal en el perfil para verificar el estado:

```dart
// En profile.dart, agregar un botón temporal:
ElevatedButton(
  onPressed: () async {
    final enabled = await StorageService.isBiometricEnabled();
    final email = await StorageService.getBiometricEmail();
    final password = await StorageService.getBiometricPassword();
    
    print('🔐 Estado de biometría:');
    print('  - Habilitada: $enabled');
    print('  - Email guardado: ${email != null ? "✅" : "❌"}');
    print('  - Password guardado: ${password != null ? "✅" : "❌"}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ver logs en consola')),
    );
  },
  child: Text('🐛 Debug Biometría'),
)
```

### 8. Checklist de Verificación

- [ ] El dispositivo tiene sensor de huella/Face ID
- [ ] La huella/rostro está registrado en el dispositivo
- [ ] La app tiene permisos de biometría
- [ ] El backend está corriendo
- [ ] Hay conexión a internet
- [ ] Las credenciales son correctas
- [ ] Se habilitó la biometría en el primer login
- [ ] Se cerró la app completamente antes de probar

### 9. Información del Dispositivo

Para ayudarte mejor, necesito saber:
- ¿Qué dispositivo estás usando? (marca y modelo)
- ¿Qué tipo de biometría tiene? (huella, Face ID, etc.)
- ¿Qué versión de Android/iOS?
- ¿Es un dispositivo físico o emulador?

---

## Próximos Pasos

1. **Ejecuta la app con logs**: `flutter run`
2. **Copia los logs** que aparecen en la consola
3. **Comparte los logs** para que pueda ver exactamente qué está fallando

Los logs te dirán exactamente en qué paso está fallando el proceso.
