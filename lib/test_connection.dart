import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Probando conexión al backend...');

  // Probar diferentes URLs
  final urls = [
    'http://localhost:3001/auth/login',
    'http://10.0.2.2:3001/auth/login',
    'http://192.168.20.207:3001/auth/login',
  ];

  for (String url in urls) {
    print('\n📡 Probando: $url');
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'correo': 'test@test.com', 'contrasena': 'test123'}),
          )
          .timeout(Duration(seconds: 5));

      print('✅ Respuesta: ${response.statusCode}');
      print('📄 Body: ${response.body}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
