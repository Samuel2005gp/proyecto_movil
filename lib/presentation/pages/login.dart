import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';
import 'admin_home.dart';
import 'Cliente_home.dart';
import 'empleado_home.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        ApiConstants.login,
        {'correo': email, 'contrasena': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final role = decodedToken['rol'] ?? decodedToken['role'] ?? '';
        final userId = decodedToken['id'] ?? decodedToken['userId'] ?? 0;
        // Soporta 'nombre', 'name', 'firstName' según lo que devuelva el JWT
        final firstName = decodedToken['firstName']?.toString() ?? '';
        final lastName = decodedToken['lastName']?.toString() ?? '';
        final fullName = decodedToken['nombre']?.toString() ??
            decodedToken['name']?.toString() ??
            (firstName.isNotEmpty ? '$firstName $lastName'.trim() : 'Usuario');

        await StorageService.saveToken(token);
        await StorageService.saveRole(role);
        await StorageService.saveUserId(userId);
        await StorageService.saveUserName(fullName);

        if (!mounted) return;
        _navigateToHome(role);
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? 'Credenciales incorrectas');
      }
    } catch (e) {
      _showError('Error de conexión: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome(String role) {
    Widget homeScreen;
    if (role == 'Admin') {
      homeScreen = const AdminHomeScreen();
    } else if (role == 'Cliente') {
      homeScreen = const ClienteHomeScreen();
    } else if ([
      'Manicurista',
      'Estilista',
      'Barbero',
      'Masajista',
      'Cosmetóloga'
    ].contains(role)) {
      homeScreen = const EmpleadoHomeScreen();
    } else {
      _showError('Rol no reconocido');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => homeScreen),
    );
  }

  void _showError(String message) => SnackBarHelper.showError(context, message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.primary,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spa,
                        size: 60, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Iniciar Sesión',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bienvenido de vuelta',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.muted,
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Iniciar Sesión'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(color: AppTheme.muted, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: Text(
                          'Regístrate',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
