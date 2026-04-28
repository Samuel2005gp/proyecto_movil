# Configuración Backend - Flutter

## 🚀 Pasos para conectar Flutter con el Backend

### 1. Backend ya está corriendo ✅
El backend está configurado y corriendo en el puerto 3001.

### 2. Configuración de IP para Flutter

#### Para Emulador Android:
- La configuración actual usa `10.0.2.2:3001` que es la IP especial del emulador
- No necesitas cambiar nada si usas emulador

#### Para Dispositivo Físico:
1. Obtén tu IP local ejecutando en terminal:
   ```bash
   ipconfig
   ```
2. Busca tu IP en la sección "Adaptador de Ethernet" o "Adaptador de LAN inalámbrica"
3. Cambia en `lib/core/constants/api_constants.dart`:
   ```dart
   static const bool _isEmulator = false; // Cambiar a false
   return 'http://TU_IP_LOCAL:3001'; // Reemplazar con tu IP
   ```

### 3. Verificar conexión
1. Asegúrate de que el backend esté corriendo (ya está ✅)
2. Ejecuta Flutter:
   ```bash
   cd proyecto_movil
   flutter run
   ```

### 4. Troubleshooting

#### Si no conecta:
- Verifica que el backend esté corriendo en puerto 3001
- Verifica que tu firewall permita conexiones en puerto 3001
- Para dispositivo físico, asegúrate de estar en la misma red WiFi

#### Comandos útiles:
```bash
# Ver tu IP
ipconfig

# Reiniciar backend
cd backend-highsoft-sena
npm run dev

# Ejecutar Flutter
cd proyecto_movil
flutter run
```

## 📱 Estado Actual
- ✅ Backend corriendo en puerto 3001
- ✅ CORS configurado
- ✅ Flutter configurado para emulador (10.0.2.2:3001)
- ✅ Dependencias HTTP instaladas

¡Todo listo para funcionar! 🎉