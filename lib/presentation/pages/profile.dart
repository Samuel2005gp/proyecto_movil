import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/models/user_model.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkBiometricStatus();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final role = await StorageService.getRole();
      final userId = await StorageService.getUserId();

      http.Response? response;

      if (role == 'Admin' && userId != null) {
        response = await ApiService.get(ApiConstants.userDetail(userId));
      } else if ([
        'Manicurista',
        'Estilista',
        'Barbero',
        'Masajista',
        'Cosmetologa'
      ].contains(role)) {
        response = await ApiService.get(ApiConstants.miPerfilEmpleado);
      } else if (role == 'Cliente' && userId != null) {
        response = await ApiService.get(ApiConstants.miPerfilCliente);
      }

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data);
        // Si el nombre vino vacío del API, complementar con el storage
        if (user.nombre.isEmpty) {
          await _loadFromStorage();
          return;
        }
        // Guardar el nombre actualizado en storage
        await StorageService.saveUserName(
            '${user.nombre} ${user.apellido}'.trim());
        setState(() {
          _user = user;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    await _loadFromStorage();
  }

  Future<void> _checkBiometricStatus() async {
    final available = await BiometricService.isBiometricAvailable();
    final enabled = await StorageService.isBiometricEnabled();
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _loadFromStorage() async {
    final userName = await StorageService.getUserName();
    final userId = await StorageService.getUserId();
    final role = await StorageService.getRole();
    final parts = (userName ?? '').trim().split(' ');
    final nombre =
        parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'Usuario';
    final apellido = parts.length > 1 ? parts.skip(1).join(' ') : '';
    setState(() {
      _user = UserModel(
          id: userId ?? 0,
          nombre: nombre,
          apellido: apellido,
          correo: '',
          telefono: '',
          rol: role ?? '',
          estado: 'Activo',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now());
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesion'),
        content: const Text('Esta seguro de que deseas cerrar sesion?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar Sesion',
                  style: TextStyle(color: AppTheme.destructive))),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.clearAll();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false);
    }
  }

  String _getInitials() {
    final n = _user?.nombre ?? '';
    final a = _user?.apellido ?? '';
    if (n.isNotEmpty && a.isNotEmpty) return '${n[0]}${a[0]}'.toUpperCase();
    if (n.isNotEmpty) return n[0].toUpperCase();
    // Fallback al correo
    final correo = _user?.correo ?? '';
    if (correo.isNotEmpty) return correo[0].toUpperCase();
    return '?';
  }

  String get _displayName {
    final nombre = _user?.nombreCompleto ?? '';
    if (nombre.isNotEmpty) return nombre;
    return _user?.correo ?? 'Usuario';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                children: [
                  const Text('Mi Cuenta',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.muted)),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                      icon: Icons.person_outline,
                      label: 'Editar Perfil',
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    EditProfileScreen(user: _user!)));
                        if (updated == true) _loadUserProfile();
                      }),
                  _buildOptionTile(
                      icon: Icons.lock_outline,
                      label: 'Cambiar Contraseña',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ChangePasswordScreen()))),

                  // Opción de autenticación biométrica
                  if (_biometricAvailable) _buildBiometricToggle(),

                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(children: [
        CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Text(_getInitials(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_displayName,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (_user!.correo.isNotEmpty && _user!.nombre.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(_user!.correo,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          if (_user!.rol.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_user!.rol,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ])),
      ]),
    );
  }

  Widget _buildOptionTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
            ]),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppTheme.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          const Icon(Icons.chevron_right, color: AppTheme.muted),
        ]),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar Sesion'),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.destructive,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
          ]),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.fingerprint,
                color: AppTheme.primary, size: 22)),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Acceso Biométrico',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              SizedBox(height: 2),
              Text('Huella o reconocimiento facial',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            ],
          ),
        ),
        Switch(
          value: _biometricEnabled,
          onChanged: _toggleBiometric,
          activeColor: AppTheme.primary,
        ),
      ]),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Habilitar biometría
      final biometricType = await BiometricService.getBiometricTypeMessage();

      // Solicitar credenciales para guardar
      final credentials = await _showCredentialsDialog();

      if (credentials == null) {
        // Usuario canceló
        return;
      }

      // Verificar credenciales con el servidor
      try {
        print('🔐 Verificando credenciales: ${credentials['email']}');

        final response = await ApiService.post(
          ApiConstants.login,
          {
            'correo': credentials['email'],
            'contrasena': credentials['password']
          },
        );

        print('🔐 Respuesta del servidor: ${response.statusCode}');

        if (!mounted) return;

        if (response.statusCode == 200) {
          // Guardar credenciales y habilitar
          print('🔐 Credenciales correctas, guardando...');

          await StorageService.saveBiometricCredentials(
            credentials['email']!,
            credentials['password']!,
          );
          await StorageService.setBiometricEnabled(true);

          // Verificar que se guardaron
          final savedEmail = await StorageService.getBiometricEmail();
          final savedPassword = await StorageService.getBiometricPassword();
          print(
              '🔐 Guardado - Email: ${savedEmail != null ? "✅" : "❌"}, Password: ${savedPassword != null ? "✅" : "❌"}');

          if (mounted) {
            setState(() => _biometricEnabled = true);
            SnackBarHelper.showSuccess(
              context,
              '$biometricType habilitado correctamente',
            );
          }
        } else {
          print('❌ Credenciales incorrectas');
          if (mounted) {
            SnackBarHelper.showError(context,
                'Credenciales incorrectas. Verifica tu correo y contraseña.');
          }
        }
      } catch (e) {
        print('❌ Error al verificar credenciales: $e');

        if (mounted) {
          SnackBarHelper.showError(context, 'Error al verificar credenciales');
        }
      }
    } else {
      // Deshabilitar biometría
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deshabilitar Acceso Biométrico'),
          content: const Text(
              '¿Estás seguro de que deseas deshabilitar el acceso biométrico?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Deshabilitar',
                  style: TextStyle(color: AppTheme.destructive)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await StorageService.clearBiometricCredentials();
        await StorageService.setBiometricEnabled(false);
        setState(() => _biometricEnabled = false);

        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Acceso biométrico deshabilitado');
      }
    }
  }

  Future<Map<String, String>?> _showCredentialsDialog() async {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _CredentialsDialog(),
    );
  }
}

// EDITAR PERFIL
class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _documentCtrl;
  late TextEditingController _correoCtrl;
  String? _selectedDocType;
  bool _isSaving = false;

  static const _docTypes = ['CC', 'TI', 'CE', 'Pasaporte', 'NIT'];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.user.nombre);
    _apellidoCtrl = TextEditingController(text: widget.user.apellido);
    _telefonoCtrl = TextEditingController(text: widget.user.telefono);
    _documentCtrl = TextEditingController(text: widget.user.document);
    _correoCtrl = TextEditingController(text: widget.user.correo);
    _selectedDocType =
        widget.user.documentType.isNotEmpty ? widget.user.documentType : null;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _documentCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final role = await StorageService.getRole();
      http.Response response;

      if (role == 'Admin') {
        response = await ApiService.put(
          ApiConstants.userDetail(widget.user.id),
          {
            'firstName': _nombreCtrl.text.trim(),
            'lastName': _apellidoCtrl.text.trim(),
            'phone': _telefonoCtrl.text.trim(),
            'role': widget.user.rol,
            if (_selectedDocType != null) 'documentType': _selectedDocType,
            if (_documentCtrl.text.trim().isNotEmpty)
              'document': _documentCtrl.text.trim(),
          },
        );
      } else if ([
        'Manicurista',
        'Estilista',
        'Barbero',
        'Masajista',
        'Cosmetologa'
      ].contains(role)) {
        response = await ApiService.put(
          ApiConstants.updateMiPerfilEmpleado,
          {
            'nombre': _nombreCtrl.text.trim(),
            'apellido': _apellidoCtrl.text.trim(),
            'telefono': _telefonoCtrl.text.trim(),
            if (_selectedDocType != null) 'tipo_documento': _selectedDocType,
            if (_documentCtrl.text.trim().isNotEmpty)
              'numero_documento': _documentCtrl.text.trim(),
          },
        );
      } else {
        response = await ApiService.patch(
          ApiConstants.miPerfilCliente,
          {
            'firstName': _nombreCtrl.text.trim(),
            'lastName': _apellidoCtrl.text.trim(),
            'phone': _telefonoCtrl.text.trim(),
            if (_selectedDocType != null) 'documentType': _selectedDocType,
            if (_documentCtrl.text.trim().isNotEmpty)
              'document': _documentCtrl.text.trim(),
          },
        );
      }

      if (response.statusCode == 200) {
        await StorageService.saveUserName(
            '${_nombreCtrl.text.trim()} ${_apellidoCtrl.text.trim()}'.trim());
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Perfil actualizado correctamente');
        Navigator.pop(context, true);
      } else {
        String errorMsg = 'Error ${response.statusCode}: ${response.body}';
        try {
          final error = jsonDecode(response.body);
          errorMsg = error['error']?.toString() ??
              error['message']?.toString() ??
              'Error ${response.statusCode}';
        } catch (_) {}
        if (!mounted) return;
        SnackBarHelper.showError(context, errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
          context, 'Excepción: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            Center(
                child: CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
              child: Text(
                widget.user.nombre.isNotEmpty
                    ? widget.user.nombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 32,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold),
              ),
            )),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nombreCtrl,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]')),
              ],
              decoration: const InputDecoration(
                  labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (RegExp(r'\d').hasMatch(v)) return 'No se permiten números';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apellidoCtrl,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]')),
              ],
              decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.person_2_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (RegExp(r'\d').hasMatch(v)) return 'No se permiten números';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) {
                if (v != null && v.isNotEmpty && v.length < 7) {
                  return 'Mínimo 7 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDocType,
              decoration: const InputDecoration(
                  labelText: 'Tipo de documento',
                  prefixIcon: Icon(Icons.badge_outlined)),
              items: _docTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDocType = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: const InputDecoration(
                  labelText: 'Número de documento',
                  prefixIcon: Icon(Icons.numbers_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _correoCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Correo',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: AppTheme.border.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar Cambios'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// CAMBIAR CONTRASENA
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSaving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final response = await ApiService.post(
        ApiConstants.changePassword,
        {
          'contrasenaActual': _currentCtrl.text,
          'nuevaPassword': _newCtrl.text,
        },
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Contraseña actualizada correctamente');
        Navigator.pop(context);
      } else {
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final error = jsonDecode(response.body);
          errorMsg = error['error']?.toString() ??
              error['message']?.toString() ??
              errorMsg;
        } catch (_) {}
        if (!mounted) return;
        SnackBarHelper.showError(context, errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
          context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar Contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _formKey,
            child: Column(children: [
              const SizedBox(height: 12),
              TextFormField(
                  controller: _currentCtrl,
                  obscureText: !_showCurrent,
                  decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                          icon: Icon(_showCurrent
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _showCurrent = !_showCurrent))),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Campo requerido' : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _newCtrl,
                  obscureText: !_showNew,
                  decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                          icon: Icon(_showNew
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _showNew = !_showNew))),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                          icon: Icon(_showConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm))),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (v != _newCtrl.text)
                      return 'Las contraseñas no coinciden';
                    return null;
                  }),
              const SizedBox(height: 32),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Actualizar Contraseña'))),
            ])),
      ),
    );
  }
}

// DIALOGO DE CREDENCIALES PARA BIOMETRIA
class _CredentialsDialog extends StatefulWidget {
  const _CredentialsDialog();

  @override
  State<_CredentialsDialog> createState() => _CredentialsDialogState();
}

class _CredentialsDialogState extends State<_CredentialsDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos'),
          backgroundColor: AppTheme.destructive,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).pop({'email': email, 'password': password});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar Credenciales'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ingresa tus credenciales para habilitar el acceso biométrico',
            style: TextStyle(fontSize: 14, color: AppTheme.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
