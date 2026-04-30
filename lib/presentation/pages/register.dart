import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _numDocCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _tipoDocSelected;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _numDocCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(
        ApiConstants.clients,
        {
          'firstName': _nombreCtrl.text.trim(),
          'lastName': _apellidoCtrl.text.trim(),
          'email': _correoCtrl.text.trim(),
          'phone': _telefonoCtrl.text.trim(),
          'documentType': _tipoDocSelected ?? '',
          'document': _numDocCtrl.text.trim(),
          'contrasena': _passwordCtrl.text,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(
            context, 'Cuenta creada exitosamente. Inicia sesión.');
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body);
        _showError(
            error['error'] ?? error['message'] ?? 'Error al crear la cuenta');
      }
    } catch (e) {
      _showError('Error de conexión: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) => SnackBarHelper.showError(context, message);

  // ── Validadores ──────────────────────────────────────────────────────────

  String? _validateNombre(String? v) {
    if (v == null || v.trim().isEmpty) return 'El nombre es requerido';
    if (v.trim().length < 2) return 'Mínimo 2 caracteres';
    if (v.trim().length > 50) return 'Máximo 50 caracteres';
    return null;
  }

  String? _validateApellido(String? v) {
    if (v == null || v.trim().isEmpty) return 'El apellido es requerido';
    if (v.trim().length < 2) return 'Mínimo 2 caracteres';
    if (v.trim().length > 50) return 'Máximo 50 caracteres';
    return null;
  }

  String? _validateCorreo(String? v) {
    if (v == null || v.trim().isEmpty) return 'El correo es requerido';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validateTelefono(String? v) {
    if (v == null || v.trim().isEmpty) return 'El teléfono es requerido';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return 'Mínimo 7 dígitos';
    if (digits.length > 15) return 'Máximo 15 dígitos';
    return null;
  }

  String? _validateNumDoc(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'El número de documento es requerido';
    }
    if (v.trim().length < 4) return 'Mínimo 4 caracteres';
    if (v.trim().length > 20) return 'Máximo 20 caracteres';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es requerida';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    if (v.length > 50) return 'Máximo 50 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
      return 'Debe contener al menos una letra';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return 'Debe contener al menos un número';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  // ── Estilo de inputs ─────────────────────────────────────────────────────

  InputDecoration _inputDec(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.destructive, width: 1.5),
      ),
    );
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
              const SizedBox(height: 48),

              // ── Ícono ────────────────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.spa, size: 46, color: Colors.white),
              ),
              const SizedBox(height: 28),

              // ── Título ───────────────────────────────────────────────
              Text(
                'Crear Cuenta',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.foreground,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Regístrate para agendar tus citas',
                style: TextStyle(fontSize: 14, color: AppTheme.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Formulario ───────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
                      ],
                      decoration: _inputDec('Nombre *', Icons.person_outline),
                      validator: _validateNombre,
                    ),
                    const SizedBox(height: 14),

                    // Apellido
                    TextFormField(
                      controller: _apellidoCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
                      ],
                      decoration:
                          _inputDec('Apellido *', Icons.person_2_outlined),
                      validator: _validateApellido,
                    ),
                    const SizedBox(height: 14),

                    // Correo
                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDec(
                          'Correo electrónico *', Icons.email_outlined),
                      validator: _validateCorreo,
                    ),
                    const SizedBox(height: 14),

                    // Teléfono
                    TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d\+\-\s]')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: _inputDec('Teléfono *', Icons.phone_outlined),
                      validator: _validateTelefono,
                    ),
                    const SizedBox(height: 14),

                    // Tipo de documento
                    DropdownButtonFormField<String>(
                      value: _tipoDocSelected,
                      decoration: _inputDec(
                          'Tipo de documento *', Icons.badge_outlined),
                      items: const [
                        DropdownMenuItem(
                            value: 'CC', child: Text('Cédula de Ciudadanía')),
                        DropdownMenuItem(
                            value: 'CE', child: Text('Cédula de Extranjería')),
                        DropdownMenuItem(
                            value: 'TI', child: Text('Tarjeta de Identidad')),
                        DropdownMenuItem(value: 'PA', child: Text('Pasaporte')),
                        DropdownMenuItem(value: 'NIT', child: Text('NIT')),
                      ],
                      onChanged: (v) => setState(() => _tipoDocSelected = v),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Selecciona un tipo de documento'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Número de documento
                    TextFormField(
                      controller: _numDocCtrl,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9\-]')),
                        LengthLimitingTextInputFormatter(20),
                      ],
                      decoration: _inputDec(
                          'Número de documento *', Icons.numbers_outlined),
                      validator: _validateNumDoc,
                    ),
                    const SizedBox(height: 14),

                    // Contraseña
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_showPassword,
                      decoration: _inputDec(
                        'Contraseña * (mín. 6 chars con letras y números)',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppTheme.muted,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: _validatePassword,
                      onChanged: (_) {
                        if (_confirmCtrl.text.isNotEmpty) {
                          _formKey.currentState?.validate();
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirmar contraseña
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showConfirm,
                      decoration: _inputDec(
                        'Confirmar contraseña *',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _showConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppTheme.muted,
                          ),
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                      validator: _validateConfirm,
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '* Campos obligatorios',
                        style: TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón crear cuenta
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                            : const Text('Crear Cuenta',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Volver al login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿Ya tienes cuenta? ',
                            style:
                                TextStyle(color: AppTheme.muted, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Inicia sesión',
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
            ],
          ),
        ),
      ),
    );
  }
}
