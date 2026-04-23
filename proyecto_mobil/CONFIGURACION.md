# Configuración del Proyecto Flutter - Spa/Salón

## 📋 Requisitos Previos

- Flutter SDK instalado (versión 3.0.0 o superior)
- Dart SDK
- Android Studio / VS Code con extensiones de Flutter
- Backend corriendo en el servidor

## 🔧 Configuración Inicial

### 1. Instalar Dependencias

Ejecuta el siguiente comando en la raíz del proyecto:

```bash
cd proyecto_mobil
flutter pub get
```

### 2. Configurar la URL del Backend

Abre el archivo `lib/core/constants/api_constants.dart` y actualiza la URL base con la IP de tu servidor:

```dart
static const String baseUrl = 'http://TU_IP_LOCAL:3001/api';
```

**Ejemplos:**
- Si estás en la misma red: `http://192.168.1.100:3001/api`
- Si usas emulador Android: `http://10.0.2.2:3001/api`
- Si usas localhost en web: `http://localhost:3001/api`

### 3. Ejecutar la Aplicación

```bash
flutter run
```

## 🎨 Sistema de Colores

El proyecto usa un sistema de colores personalizado definido en `lib/core/theme/app_theme.dart`:

- **Primary**: #1A3A2A (verde oscuro)
- **Background**: #F7F9FC (fondo general)
- **Card**: #FFFFFF (tarjetas)
- **Accent**: #78D1BD (teal - highlights)
- **Secondary**: #EAD8B1 (beige)
- **Destructive**: #EF4444 (rojo - errores)

## 📱 Roles y Navegación

### Admin
- **Credenciales de prueba**: Configurar en el backend
- **Pantallas**: Dashboard, Citas, Clientes, Ventas, Usuarios, Perfil
- **Permisos**: Acceso completo a todas las funcionalidades

### Empleado (Manicurista, Estilista, Barbero, Masajista, Cosmetóloga)
- **Pantallas**: Mis Citas, Novedades, Perfil
- **Permisos**: Ver y gestionar sus propias citas

### Cliente
- **Pantallas**: Mis Citas, Nueva Cita, Perfil
- **Permisos**: Ver y crear sus propias citas, editar perfil

## 🔐 Autenticación

La aplicación usa JWT (JSON Web Tokens) para autenticación:

1. El usuario ingresa correo y contraseña
2. El backend valida y devuelve un JWT
3. El token se guarda en SharedPreferences
4. Todas las peticiones autenticadas incluyen el header: `Authorization: Bearer <token>`
5. Si el token expira (401), se redirige automáticamente al login

## 📂 Estructura del Proyecto

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart       # URLs y endpoints
│   ├── services/
│   │   ├── api_service.dart         # Cliente HTTP con interceptor JWT
│   │   └── storage_service.dart     # Manejo de token y datos locales
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── client_model.dart
│   │   ├── employee_model.dart
│   │   ├── appointment_model.dart
│   │   └── sale_model.dart
│   └── theme/
│       └── app_theme.dart           # Tema y colores de la app
├── presentation/
│   └── pages/
│       ├── login.dart
│       ├── admin_home.dart
│       ├── empleado_home.dart
│       ├── Cliente_home.dart
│       ├── appointments.dart
│       ├── clients.dart
│       ├── sales.dart
│       └── profile.dart
└── main.dart
```

## 🌐 Endpoints del Backend

### Autenticación
- `POST /api/auth/login` - Iniciar sesión

### Citas
- `GET /api/appointments` - Listar citas
- `POST /api/appointments` - Crear cita
- `PUT /api/appointments/:id` - Editar cita
- `PATCH /api/appointments/:id/status` - Cambiar estado
- `DELETE /api/appointments/:id` - Eliminar cita

### Clientes
- `GET /api/clients` - Listar clientes
- `POST /api/clients` - Crear cliente (público)
- `PUT /api/clients/:id` - Editar cliente
- `DELETE /api/clients/:id` - Eliminar cliente

### Ventas
- `GET /api/sales` - Listar ventas
- `POST /api/sales` - Crear venta
- `DELETE /api/sales/:id` - Eliminar venta

### Usuarios
- `GET /api/users` - Listar usuarios (admin)
- `POST /api/users` - Crear usuario (admin)
- `PUT /api/users/:id` - Editar usuario
- `DELETE /api/users/:id` - Eliminar usuario (admin)

## 🐛 Solución de Problemas

### Error de conexión
- Verifica que el backend esté corriendo
- Verifica la URL en `api_constants.dart`
- Si usas emulador Android, usa `10.0.2.2` en lugar de `localhost`

### Token expirado
- La app redirige automáticamente al login
- Vuelve a iniciar sesión

### Dependencias no instaladas
```bash
flutter clean
flutter pub get
```

## 📝 Próximos Pasos

Las siguientes pantallas necesitan ser conectadas al backend:

1. **Appointments** - Conectar a la API de citas
2. **Clients** - Conectar a la API de clientes
3. **Sales** - Conectar a la API de ventas
4. **Dashboard** - Obtener estadísticas reales del backend

Cada una debe:
- Eliminar datos quemados
- Implementar llamadas a la API
- Manejar estados de carga
- Manejar errores de red
- Actualizar la UI con datos reales

## 🚀 Compilación para Producción

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 📞 Soporte

Si encuentras problemas, verifica:
1. Logs de Flutter: `flutter logs`
2. Logs del backend
3. Respuestas de la API en la consola
