import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/google_signin_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';
import 'admin_home.dart';
import 'Cliente_home.dart';
import 'empleado_home.dart';
import 'register.dart';
import 'forgot_password.dart';

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
        final rawRole = decodedToken['rol'] ?? decodedToken['role'] ?? '';
        // Normalizar el rol para que siempre sea consistente
        final role = _normalizeRole(rawRole.toString());
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

        // Ofrecer configurar autenticación biométrica si está disponible
        await _offerBiometricSetup(email, password, role);
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

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      print('🔵 Iniciando login con Google...');
      final result = await GoogleSignInService.signInWithGoogle();
      
      if (!mounted) return;
      
      final usuario = result['usuario'] as Map<String, dynamic>;
      final role = usuario['rol'] ?? 'Cliente';
      
      print('✅ Login con Google exitoso. Rol: $role');
      
      // No ofrecer biometría para Google Sign-In ya que Google maneja su propia autenticación
      _navigateToHome(role);
      
    } catch (e) {
      print('❌ Error en login con Google: $e');
      if (!mounted) return;
      _showError('Error al iniciar sesión con Google: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome(String role) {
    Widget homeScreen;
    final rolNorm = role.trim().toLowerCase();

    if (rolNorm == 'admin' || rolNorm == 'administrador') {
      homeScreen = const AdminHomeScreen();
    } else if (rolNorm == 'cliente') {
      homeScreen = const ClienteHomeScreen();
    } else if ([
      'manicurista',
      'estilista',
      'barbero',
      'masajista',
      'cosmetóloga',
      'cosmetologa',
      'empleado',
    ].contains(rolNorm)) {
      homeScreen = const EmpleadoHomeScreen();
    } else {
      _showError('Rol no reconocido: $role');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => homeScreen),
    );
  }

  void _showError(String message) => SnackBarHelper.showError(context, message);

  Future<void> _offerBiometricSetup(
      String email, String password, String role) async {
    print('🔐 _offerBiometricSetup iniciado');

    // Verificar si ya está habilitado
    final alreadyEnabled = await StorageService.isBiometricEnabled();
    print('🔐 Biometría ya habilitada: $alreadyEnabled');

    if (alreadyEnabled) {
      _navigateToHome(role);
      return;
    }

    // Verificar si el dispositivo soporta biometría
    final isAvailable = await BiometricService.isBiometricAvailable();
    print('🔐 Biometría disponible en dispositivo: $isAvailable');

    if (!isAvailable) {
      _navigateToHome(role);
      return;
    }

    // Obtener el tipo de biometría disponible
    final biometricType = await BiometricService.getBiometricTypeMessage();
    print('🔐 Tipo de biometría: $biometricType');

    if (!mounted) return;

    // Mostrar diálogo para configurar biometría
    final shouldEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: AppTheme.primary, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Acceso Rápido')),
          ],
        ),
        content: Text(
          '¿Deseas habilitar $biometricType para iniciar sesión más rápido la próxima vez?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );

    print('🔐 Usuario eligió habilitar: $shouldEnable');

    if (shouldEnable == true) {
      // Guardar credenciales y habilitar biometría
      print('🔐 Guardando credenciales: $email');
      await StorageService.saveBiometricCredentials(email, password);
      await StorageService.setBiometricEnabled(true);

      // Verificar que se guardaron correctamente
      final savedEmail = await StorageService.getBiometricEmail();
      final savedPassword = await StorageService.getBiometricPassword();
      print(
          '🔐 Credenciales guardadas - Email: ${savedEmail != null ? "✅" : "❌"}, Password: ${savedPassword != null ? "✅" : "❌"}');

      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        '$biometricType habilitado correctamente',
      );
    }

    if (!mounted) return;
    _navigateToHome(role);
  }

  /// Normaliza el nombre del rol para que siempre sea consistente
  /// independientemente de cómo esté guardado en la BD
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
        return 'Manicurista'; // fallback genérico de empleado
      default:
        return raw; // devuelve tal cual si no se reconoce
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // ── Logo de la empresa ─────────────────────────────────────
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/high_life_logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // ── Campo correo ─────────────────────────────────────────
              _buildField(
                controller: _emailController,
                hint: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // ── Campo contraseña ─────────────────────────────────────
              _buildField(
                controller: _passwordController,
                hint: 'Contraseña',
                icon: Icons.lock_outline,
                obscure: !_showPassword,
                suffix: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.muted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              const SizedBox(height: 8),

              // ── Olvidé contraseña ────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── Botón Iniciar Sesión ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Divisor "O" ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.muted.withValues(alpha: 0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'O',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.muted.withValues(alpha: 0.3))),
                ],
              ),
              const SizedBox(height: 20),

              // ── Botón Google Sign-In ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      // Si no existe el logo, usar un icono
                      return const Icon(Icons.g_mobiledata, size: 28);
                    },
                  ),
                  label: const Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.foreground,
                    side: BorderSide(color: AppTheme.muted.withValues(alpha: 0.3), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Registro ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes cuenta? ',
                      style: TextStyle(color: AppTheme.muted, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: Text(
                      'Regístrate',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.muted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.muted, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
