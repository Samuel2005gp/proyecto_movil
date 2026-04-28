# ✅ Backend Funcionando - Instrucciones para Flutter

## 🎯 Estado Actual
- ✅ Backend corriendo en puerto 3001
- ✅ Base de datos configurada
- ✅ Usuarios de prueba creados
- ✅ API respondiendo correctamente

## 👥 Usuarios de Prueba Disponibles

### Cliente
- **Email:** `cliente@highlife.com`
- **Contraseña:** `cliente123`

### Empleados
- **Estilista:** `estilista@highlife.com` / `estilista123`
- **Manicurista:** `manicurista@highlife.com` / `manicurista123`
- **Barbero:** `barbero@highlife.com` / `barbero123`
- **Masajista:** `masajista@highlife.com` / `masajista123`
- **Cosmetóloga:** `cosmetologa@highlife.com` / `cosmetologa123`

## 🔧 Configuración Flutter

### Para Emulador Android (configuración actual):
```dart
// En api_constants.dart
static const bool _isEmulator = true;
// Usa: http://10.0.2.2:3001
```

### Para Dispositivo Físico:
```dart
// En api_constants.dart
static const bool _isEmulator = false;
// Usa: http://192.168.20.207:3001
```

## 🚀 Pasos para Probar

1. **Asegúrate de que el backend esté corriendo:**
   ```bash
   cd backend-highsoft-sena
   npm run dev
   ```

2. **Ejecuta Flutter:**
   ```bash
   cd proyecto_movil
   flutter run
   ```

3. **Prueba el login con:**
   - Email: `cliente@highlife.com`
   - Contraseña: `cliente123`

## 🔍 Troubleshooting

### Si sigue dando "failed to fetch":

1. **Verifica la configuración de red:**
   - Para emulador: usa `10.0.2.2:3001`
   - Para dispositivo físico: usa `192.168.20.207:3001`

2. **Verifica que el firewall permita conexiones en puerto 3001**

3. **Prueba desde el navegador del emulador:**
   - Abre: `http://10.0.2.2:3001/auth/login`
   - Debería mostrar un error de método (normal)

4. **Revisa los logs de Flutter para más detalles del error**

## 📱 Próximos Pasos
Una vez que el login funcione, podrás:
- Navegar entre pantallas según el rol
- Crear citas
- Ver servicios disponibles
- Gestionar perfil

¡El backend está listo y funcionando! 🎉