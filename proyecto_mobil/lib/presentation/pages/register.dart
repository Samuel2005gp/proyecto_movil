import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

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
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'correo': _correoCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim(),
          'tipoDocumento': _tipoDocSelected ?? '',
          'documento': _numDocCtrl.text.trim(),
          'contrasena': _passwordCtrl.text,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada exitosamente. Inicia sesión.'),
            backgroundColor: AppTheme.colorSuccess,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? 'Error al crear la cuenta');
      }
    } catch (e) {
      _showError('Error de conexión: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.destructive,
      ),
    );
  }

  // ── Validadores ──────────────────────────────────────────────────────────

  String? _validateNombre(String? v) {
    if (v == null || v.trim().isEmpty) return 'El nombre es requerido';
    if (v.trim().length < 2) return 'Mínimo 2 caracteres';
    if (v.trim().length > 50) return 'Máximo 50 caracteres';
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(v.trim())) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  String? _validateApellido(String? v) {
    if (v == null || v.trim().isEmpty) return 'El apellido es requerido';
    if (v.trim().length < 2) return 'Mínimo 2 caracteres';
    if (v.trim().length > 50) return 'Máximo 50 caracteres';
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(v.trim())) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  String? _validateCorreo(String? v) {
    if (v == null || v.trim().isEmpty) return 'El correo es requerido';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim())) {
      return 'Ingresa un correo válido (ej: usuario@correo.com)';
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
    if (v == null || v.trim().isEmpty)
      return 'El número de documento es requerido';
    if (!RegExp(r'^[a-zA-Z0-9\-]+$').hasMatch(v.trim())) {
      return 'Solo letras, números y guiones';
    }
    if (v.trim().length < 4) return 'Mínimo 4 caracteres';
    if (v.trim().length > 20) return 'Máximo 20 caracteres';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es requerida';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    if (v.length > 50) return 'Máximo 50 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(v))
      return 'Debe contener al menos una letra';
    if (!RegExp(r'[0-9]').hasMatch(v))
      return 'Debe contener al menos un número';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícono
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_outlined,
                          size: 48, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 20),

                    Text('Crear Cuenta',
                        style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 6),
                    Text(
                      'Regístrate para agendar tus citas',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // ── Nombre ──────────────────────────────────────────
                    TextFormField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Ej: María',
                      ),
                      validator: _validateNombre,
                    ),
                    const SizedBox(height: 14),

                    // ── Apellido ─────────────────────────────────────────
                    TextFormField(
                      controller: _apellidoCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Apellido *',
                        prefixIcon: Icon(Icons.person_2_outlined),
                        hintText: 'Ej: García',
                      ),
                      validator: _validateApellido,
                    ),
                    const SizedBox(height: 14),

                    // ── Correo ───────────────────────────────────────────
                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico *',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'usuario@correo.com',
                      ),
                      validator: _validateCorreo,
                    ),
                    const SizedBox(height: 14),

                    // ── Teléfono ─────────────────────────────────────────
                    TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d\+\-\s]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Teléfono *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: 'Ej: 3001234567',
                      ),
                      validator: _validateTelefono,
                    ),
                    const SizedBox(height: 14),

                    // ── Tipo de documento ────────────────────────────────
                    DropdownButtonFormField<String>(
                      initialValue: _tipoDocSelected,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de documento *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
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

                    // ── Número de documento ──────────────────────────────
                    TextFormField(
                      controller: _numDocCtrl,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9\-]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Número de documento *',
                        prefixIcon: Icon(Icons.numbers_outlined),
                        hintText: 'Ej: 1234567890',
                      ),
                      validator: _validateNumDoc,
                    ),
                    const SizedBox(height: 14),

                    // ── Contraseña ───────────────────────────────────────
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Mínimo 6 caracteres con letras y números',
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: _validatePassword,
                      onChanged: (_) {
                        // Revalida confirmar cuando cambia la contraseña
                        if (_confirmCtrl.text.isNotEmpty) {
                          _formKey.currentState?.validate();
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Confirmar contraseña ─────────────────────────────
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Repite tu contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(_showConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                      validator: _validateConfirm,
                    ),

                    const SizedBox(height: 8),
                    // Nota de campos obligatorios
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '* Campos obligatorios',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Botón registrar ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Crear Cuenta'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Volver al login ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta? ',
                          style: TextStyle(color: AppTheme.muted, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Inicia sesión',
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
      ),
    );
  }
}
