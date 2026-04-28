import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Diagnóstico de Conexión');
  print('=' * 50);

  // URLs a probar
  final urls = [
    'http://localhost:3001',
    'http://10.0.2.2:3001',
    'http://192.168.20.207:3001',
    'http://127.0.0.1:3001',
  ];

  for (String baseUrl in urls) {
    print('\n📡 Probando: $baseUrl');

    try {
      // Probar conexión básica
      final response = await http.get(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 3));

      print('✅ Conexión exitosa - Status: ${response.statusCode}');

      // Probar login
      final loginResponse = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'correo': 'cliente@highlife.com', 'contrasena': 'cliente123'}),
          )
          .timeout(Duration(seconds: 5));

      if (loginResponse.statusCode == 200) {
        print('🎉 LOGIN EXITOSO!');
        final data = jsonDecode(loginResponse.body);
        print('Token recibido: ${data['token']?.substring(0, 20)}...');
      } else {
        print('❌ Login falló: ${loginResponse.statusCode}');
        print('Respuesta: ${loginResponse.body}');
      }
    } catch (e) {
      if (e is SocketException) {
        print('❌ Error de red: No se puede conectar');
      } else {
        print('❌ Error: $e');
      }
    }
  }

  print('\n' + '=' * 50);
  print('🔧 Recomendaciones:');
  print('- Si ninguna URL funciona, verifica que el backend esté corriendo');
  print('- Si solo localhost funciona, hay problema de red con el emulador');
  print('- Si 10.0.2.2 funciona, usar esa para emulador');
  print('- Si 192.168.20.207 funciona, usar esa para dispositivo físico');
}
