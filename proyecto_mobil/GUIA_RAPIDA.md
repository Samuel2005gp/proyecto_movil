# 🚀 Guía Rápida - App Conectada al Backend

## ✅ Estado: 100% Conectado - Sin Datos Quemados

---

## 📋 Paso 1: Configurar la URL del Backend

Abre el archivo `lib/core/constants/api_constants.dart` y cambia la IP:

```dart
static const String baseUrl = 'http://TU_IP_LOCAL:3001/api';
```

**Ejemplos:**
- Misma red WiFi: `http://192.168.1.100:3001/api`
- Emulador Android: `http://10.0.2.2:3001/api`
- Localhost (web): `http://localhost:3001/api`

---

## 🏃 Paso 2: Ejecutar la Aplicación

```bash
cd proyecto_mobil
flutter run
```

Selecciona tu dispositivo (Chrome, Android, iOS, etc.)

---

## 🔐 Paso 3: Iniciar Sesión

Usa credenciales válidas de tu backend. La app redirigirá automáticamente según el rol:

- **Admin** → Dashboard completo
- **Empleado** → Mis citas y perfil
- **Cliente** → Mis citas y perfil

---

## 📱 Funcionalidades por Pantalla

### 🏠 Dashboard (Solo Admin)
**Datos en tiempo real:**
- Citas de hoy
- Total de clientes
- Ventas del día
- Próximas 3 citas

**Acciones:**
- Pull-to-refresh para actualizar
- Accesos rápidos a otras secciones

---

### 📅 Citas (Appointments)
**Datos filtrados por rol:**
- Admin: Todas las citas
- Empleado: Solo sus citas
- Cliente: Solo sus citas

**Acciones:**
- Ver citas en calendario
- Completar cita (botón ✓)
- Cancelar cita (botón ✗)
- Eliminar cita (botón 🗑️)
- Pull-to-refresh

---

### 👥 Clientes (Clients)
**Datos:**
- Lista completa de clientes

**Acciones:**
- Buscar por nombre, correo o teléfono
- Ver detalles del cliente
- Eliminar cliente
- Pull-to-refresh

---

### 💰 Ventas (Sales)
**Datos:**
- Lista de todas las ventas
- Total del día
- Total del mes

**Acciones:**
- Ver detalles de cada venta
- Eliminar venta
- Pull-to-refresh

---

### 👤 Perfil (Profile)
**Datos:**
- Información del usuario logueado

**Acciones:**
- Ver datos personales
- Cerrar sesión

---

## 🔄 Características Comunes

### Pull-to-Refresh
En todas las pantallas con listas, desliza hacia abajo para recargar datos.

### Estados de Carga
Mientras carga datos, verás un indicador circular.

### Manejo de Errores
Si algo falla:
1. Verás un mensaje de error
2. Botón "Reintentar" para volver a intentar
3. Verifica que el backend esté corriendo

### Confirmaciones
Antes de eliminar cualquier registro, se pedirá confirmación.

---

## 🐛 Solución de Problemas

### Error: "Error de conexión"
**Causa:** No puede conectar al backend

**Solución:**
1. Verifica que el backend esté corriendo
2. Verifica la URL en `api_constants.dart`
3. Si usas emulador Android, usa `10.0.2.2` en lugar de `localhost`
4. Verifica que estés en la misma red (si usas IP local)

---

### Error: "Sesión expirada"
**Causa:** El token JWT expiró

**Solución:**
- La app redirige automáticamente al login
- Vuelve a iniciar sesión

---

### Error: "No se encontraron datos"
**Causa:** No hay datos en el backend

**Solución:**
- Verifica que el backend tenga datos
- Crea algunos registros de prueba en el backend

---

### No aparecen las citas/clientes/ventas
**Causa:** Posibles problemas de permisos o filtrado

**Solución:**
1. Verifica que el usuario tenga permisos en el backend
2. Revisa los logs del backend para ver si llegan las peticiones
3. Usa las herramientas de desarrollo del navegador (F12) para ver las peticiones HTTP

---

## 📊 Endpoints que Usa la App

```
POST   /api/auth/login              → Login
GET    /api/appointments            → Listar citas
PATCH  /api/appointments/:id/status → Cambiar estado
DELETE /api/appointments/:id        → Eliminar cita
GET    /api/clients                 → Listar clientes
DELETE /api/clients/:id             → Eliminar cliente
GET    /api/sales                   → Listar ventas
DELETE /api/sales/:id               → Eliminar venta
GET    /api/users/:id               → Obtener usuario
```

---

## 🎯 Próximos Pasos (Opcional)

Si quieres agregar más funcionalidades:

### 1. Crear Nueva Cita
Implementar formulario con:
- Selector de cliente
- Selector de servicio
- Selector de empleado
- Fecha y hora
- Notas

### 2. Editar Cita
Formulario similar al de crear, pero pre-llenado con datos existentes.

### 3. Crear/Editar Cliente
Formulario con:
- Nombre
- Apellido
- Correo
- Teléfono
- Foto de perfil (opcional)

### 4. Crear Venta
Formulario con:
- Selector de cita completada
- Método de pago
- Total (calculado automáticamente)

---

## 📱 Capturas de Pantalla Esperadas

### Login
- Campos de correo y contraseña
- Botón "Iniciar Sesión"
- Fondo con gradiente verde

### Dashboard
- Header con nombre del usuario
- 4 tarjetas de estadísticas
- Accesos rápidos
- Lista de próximas citas

### Citas
- Calendario interactivo
- Lista de citas del día seleccionado
- Botones de acción (completar, cancelar, eliminar)

### Clientes
- Barra de búsqueda
- Lista de clientes con avatar
- Modal con detalles al hacer clic

### Ventas
- Tarjetas de totales (hoy y mes)
- Lista de ventas con detalles
- Botón eliminar

### Perfil
- Header con datos del usuario
- Opciones de cuenta
- Botón cerrar sesión

---

## ✨ Características Destacadas

✅ **100% Conectado al Backend** - Sin datos quemados
✅ **Filtrado por Rol** - Cada usuario ve solo lo que debe
✅ **Pull-to-Refresh** - Actualiza datos fácilmente
✅ **Manejo de Errores** - Mensajes claros y opciones de reintentar
✅ **UI/UX Profesional** - Diseño consistente y moderno
✅ **Seguridad** - JWT, validaciones, confirmaciones
✅ **Rendimiento** - Carga paralela de datos

---

## 🎉 ¡Listo!

Tu aplicación está completamente funcional y conectada al backend. Todos los datos son reales y se actualizan en tiempo real.

**¿Necesitas ayuda?** Revisa los archivos:
- `TODAS_PANTALLAS_CONECTADAS.md` - Documentación completa
- `EJEMPLO_CONEXION_API.md` - Ejemplos de código
- `CONFIGURACION.md` - Configuración detallada
