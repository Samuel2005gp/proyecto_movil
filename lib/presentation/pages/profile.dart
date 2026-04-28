import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
                      label: 'Cambiar Contrasena',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ChangePasswordScreen(userId: _user!.id)))),
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
          if (_user!.correo.isNotEmpty && _user!.nombre.isNotEmpty)
            Text(_user!.correo,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Text(_user!.rol.isNotEmpty ? _user!.rol : 'Sin rol',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
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
            'email': _correoCtrl.text.trim(),
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
        response = await ApiService.put(
          ApiConstants.updateClientePerfil(widget.user.id),
          {
            'firstName': _nombreCtrl.text.trim(),
            'lastName': _apellidoCtrl.text.trim(),
            'phone': _telefonoCtrl.text.trim(),
            'email': _correoCtrl.text.trim(),
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
              decoration: const InputDecoration(
                  labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apellidoCtrl,
              decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.person_2_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined)),
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
              decoration: const InputDecoration(
                  labelText: 'Número de documento',
                  prefixIcon: Icon(Icons.numbers_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.user.rol,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Rol',
                prefixIcon: const Icon(Icons.manage_accounts_outlined),
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
  final int userId;
  const ChangePasswordScreen({super.key, required this.userId});
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
      final response = await ApiService.put(
          ApiConstants.userDetail(widget.userId),
          {'currentPassword': _currentCtrl.text, 'newPassword': _newCtrl.text});
      if (response.statusCode == 200) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Contrasena actualizada');
        Navigator.pop(context);
      } else {
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final error = jsonDecode(response.body);
          errorMsg = error['message']?.toString() ?? errorMsg;
        } catch (_) {}
        if (!mounted) return;
        SnackBarHelper.showError(context, errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.destructive));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar Contrasena')),
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
                      labelText: 'Contrasena actual',
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
                      labelText: 'Nueva contrasena',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                          icon: Icon(_showNew
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _showNew = !_showNew))),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (v.length < 6) return 'Minimo 6 caracteres';
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  decoration: InputDecoration(
                      labelText: 'Confirmar contrasena',
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
                      return 'Las contrasenas no coinciden';
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
                          : const Text('Actualizar Contrasena'))),
            ])),
      ),
    );
  }
}
