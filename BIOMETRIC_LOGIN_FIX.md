# 🔐 Corrección: Login Biométrico Siempre Ingresaba Como Cliente

## Problema Identificado

Cuando los usuarios iniciaban sesión usando autenticación biométrica (huella dactilar), **siempre ingresaban con rol de Cliente**, independientemente del rol real de su cuenta (Admin, Empleado, etc.).

## Causa Raíz

En el archivo `lib/main.dart`, el método `_loginWithCredentials()` (líneas 283-298) **NO estaba decodificando el JWT** para extraer el rol del usuario. En su lugar, intentaba obtener el rol directamente del JSON de respuesta, lo cual no es confiable ya que el backend devuelve el rol dentro del token JWT, no en el body del response.

### Código Problemático (Antes)

```dart
if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  
  // ❌ PROBLEMA: Intenta extraer rol directamente del JSON
  final role = (data['rol'] ?? data['role'] ?? 'Usuario') as String;
  final userId = (data['id'] ?? data['userId'] ?? 0) as int;
  final userName = (data['nombre'] ?? data['name'] ?? 'Usuario') as String;
  
  await StorageService.saveRole(role);  // Guardaba rol incorrecto
  // ...
}
```

### Comparación: Login Normal vs Biométrico

**Login Normal** (`lib/presentation/pages/login.dart`):
- ✅ Decodifica el JWT correctamente
- ✅ Extrae el rol del token: `decodedToken['rol']`
- ✅ Normaliza el rol con `_normalizeRole()`
- ✅ Guarda el rol correcto

**Login Biométrico** (ANTES del fix):
- ❌ NO decodificaba el JWT
- ❌ Intentaba extraer rol del JSON (que no existe en esa estructura)
- ❌ NO normalizaba el rol
- ❌ Usaba valor por defecto 'Usuario' cuando no encontraba el rol

## Solución Implementada

### 1. Importar JWT Decoder

Se agregó el import necesario al inicio del archivo:

```dart
import 'package:jwt_decoder/jwt_decoder.dart';
```

### 2. Decodificar el JWT Correctamente

Se modificó el método `_loginWithCredentials()` para decodificar el JWT y extraer el rol correctamente:

```dart
if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  final token = data['token'] as String?;

  if (token == null || token.isEmpty) {
    // Manejar error
    return;
  }

  // 🔧 FIX: Decodificar el JWT correctamente para obtener el rol real
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
  final rawRole = decodedToken['rol'] ?? decodedToken['role'] ?? '';
  
  // Normalizar el rol para que siempre sea consistente
  final role = _normalizeRole(rawRole.toString());
  final userId = decodedToken['id'] ?? decodedToken['userId'] ?? 0;
  
  // Extraer nombre completo
  final firstName = decodedToken['firstName']?.toString() ?? '';
  final lastName = decodedToken['lastName']?.toString() ?? '';
  final fullName = decodedToken['nombre']?.toString() ??
      decodedToken['name']?.toString() ??
      (firstName.isNotEmpty ? '$firstName $lastName'.trim() : 'Usuario');

  print('✅ Login exitoso con huella');
  print('   - Token: ✅');
  print('   - Rol decodificado: $role');  // Ahora muestra el rol correcto
  print('   - UserId: $userId');
  print('   - UserName: $fullName');

  await StorageService.saveToken(token);
  await StorageService.saveRole(role);  // ✅ Guarda el rol correcto
  await StorageService.saveUserId(userId);
  await StorageService.saveUserName(fullName);

  _navigateToHome(role);  // ✅ Navega a la pantalla correcta
}
```

### 3. Agregar Función de Normalización

Se agregó la función `_normalizeRole()` en la clase `_AuthCheckerState` para asegurar consistencia en los nombres de roles:

```dart
String _normalizeRole(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'admin':
    case 'administrador':
      return 'Admin';
    case 'cliente':
      return 'Cliente';
    case 'manicurista':
      return 'Manicurista';
    case 'estilista':
      return 'Estilista';
    case 'barbero':
      return 'Barbero';
    case 'masajista':
      return 'Masajista';
    case 'cosmetóloga':
    case 'cosmetologa':
      return 'Cosmetologa';
    case 'empleado':
      return 'Manicurista'; // fallback genérico
    default:
      return raw;
  }
}
```

## Archivos Modificados

- ✅ `lib/main.dart` - Corregido el método `_loginWithCredentials()`
- ✅ `lib/main.dart` - Agregado import de `jwt_decoder`
- ✅ `lib/main.dart` - Agregada función `_normalizeRole()`

## Cómo Probar

1. **Con cuenta de Administrador:**
   - Inicia sesión normalmente con credenciales de Admin
   - Habilita la autenticación biométrica desde el perfil
   - Cierra sesión
   - Inicia sesión con huella dactilar
   - ✅ Deberías ver la pantalla de AdminHomeScreen

2. **Con cuenta de Empleado:**
   - Inicia sesión con credenciales de empleado (Manicurista, Estilista, etc.)
   - Habilita la autenticación biométrica
   - Cierra sesión
   - Inicia sesión con huella dactilar
   - ✅ Deberías ver la pantalla de EmpleadoHomeScreen

3. **Con cuenta de Cliente:**
   - Inicia sesión con credenciales de cliente
   - Habilita la autenticación biométrica
   - Cierra sesión
   - Inicia sesión con huella dactilar
   - ✅ Deberías ver la pantalla de ClienteHomeScreen

## Logs de Depuración

Ahora cuando inicies sesión con huella, verás en los logs:

```
🔐 Intentando login con: [email]
🔐 Respuesta del servidor: 200
✅ Login exitoso con huella
   - Token: ✅
   - Rol decodificado: Admin  // Muestra el rol correcto
   - UserId: 123
   - UserName: Juan Pérez
```

## Notas Adicionales

### Backend
El backend (`auth.controller.js`) **YA estaba funcionando correctamente**, devolviendo el rol dentro del JWT:

```javascript
const token = jwt.sign(
  { 
    id: usuario.id, 
    correo: usuario.correo, 
    rol: usuario.rol.nombre,  // ✅ Rol correcto en el token
    rolId: usuario.rolId 
  },
  JWT_SECRET,
  { expiresIn: "8h" }
);
```

### Seguridad
⚠️ **IMPORTANTE**: El proyecto actualmente usa `SharedPreferences` para guardar credenciales biométricas. En producción se recomienda usar `flutter_secure_storage` para mayor seguridad.

## Fecha de Corrección
19 de junio de 2026
