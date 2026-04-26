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
      } else if (['Manicurista','Estilista','Barbero','Masajista','Cosmetologa'].contains(role)) {
        response = await ApiService.get(ApiConstants.miPerfilEmpleado);
      } else if (role == 'Cliente' && userId != null) {
        response = await ApiService.get(ApiConstants.miPerfilCliente);
      }

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() { _user = UserModel.fromJson(data); _isLoading = false; });
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
    final nombre = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'Usuario';
    final apellido = parts.length > 1 ? parts.skip(1).join(' ') : '';
    setState(() {
      _user = UserModel(id: userId ?? 0, nombre: nombre, apellido: apellido,
          correo: '', telefono: '', rol: role ?? '', estado: 'Activo',
          createdAt: DateTime.now(), updatedAt: DateTime.now());
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar Sesion', style: TextStyle(color: AppTheme.destructive))),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.clearAll();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  String _getInitials() {
    final n = _user?.nombre ?? '';
    final a = _user?.apellido ?? '';
    if (n.isNotEmpty && a.isNotEmpty) return '${n[0]}${a[0]}'.toUpperCase();
    if (n.isNotEmpty) return n[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserProfile,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              const Text('Mi Cuenta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.muted)),
              const SizedBox(height: 10),
              _buildOptionTile(icon: Icons.person_outline, label: 'Editar Perfil', onTap: () async {
                final updated = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)));
                if (updated == true) _loadUserProfile();
              }),
              _buildOptionTile(icon: Icons.lock_outline, label: 'Cambiar Contrasena', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(userId: _user!.id)))),
              const SizedBox(height: 32),
              _buildLogoutButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        CircleAvatar(radius: 32, backgroundColor: Colors.white24,
            child: Text(_getInitials(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_user!.nombreCompleto, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          if (_user!.correo.isNotEmpty)
            Text(_user!.correo, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Text(_user!.rol.isNotEmpty ? _user!.rol : 'Sin rol',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ])),
      ]),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.destructive, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.user.nombre);
    _apellidoCtrl = TextEditingController(text: widget.user.apellido);
    _telefonoCtrl = TextEditingController(text: widget.user.telefono);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
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
            'email': widget.user.correo,
            'role': widget.user.rol,
          },
        );
      } else if (['Manicurista','Estilista','Barbero','Masajista','Cosmetologa'].contains(role)) {
        response = await ApiService.put(
          ApiConstants.updateMiPerfilEmpleado,
          {
            'firstName': _nombreCtrl.text.trim(),
            'lastName': _apellidoCtrl.text.trim(),
            'phone': _telefonoCtrl.text.trim(),
          },
        );
      } else {
        response = await ApiService.put(
          ApiConstants.updateClientePerfil(widget.user.id),
          {
            'nombre': _nombreCtrl.text.trim(),
            'apellido': _apellidoCtrl.text.trim(),
            'telefono': _telefonoCtrl.text.trim(),
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
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final error = jsonDecode(response.body);
          errorMsg = error['message']?.toString() ?? error['error']?.toString() ?? errorMsg;
        } catch (_) {
          errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
        }
        if (!mounted) return;
        SnackBarHelper.showError(context, errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.destructive, duration: const Duration(seconds: 5)));
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
            Center(child: CircleAvatar(radius: 40, backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: Text(widget.user.nombre.isNotEmpty ? widget.user.nombre[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 32, color: AppTheme.primary, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 28),
            TextFormField(controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _apellidoCtrl,
                decoration: const InputDecoration(labelText: 'Apellido', prefixIcon: Icon(Icons.person_2_outlined)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _telefonoCtrl, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefono', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 16),
            TextFormField(initialValue: widget.user.correo, readOnly: true,
                decoration: InputDecoration(labelText: 'Correo', prefixIcon: const Icon(Icons.email_outlined),
                    filled: true, fillColor: AppTheme.border.withOpacity(0.3))),
            const SizedBox(height: 16),
            TextFormField(initialValue: widget.user.rol, readOnly: true,
                decoration: InputDecoration(labelText: 'Rol', prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true, fillColor: AppTheme.border.withOpacity(0.3))),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity,
                child: ElevatedButton(onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar Cambios'))),
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
      final response = await ApiService.put(ApiConstants.userDetail(widget.userId),
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
        child: Form(key: _formKey, child: Column(children: [
          const SizedBox(height: 12),
          TextFormField(controller: _currentCtrl, obscureText: !_showCurrent,
              decoration: InputDecoration(labelText: 'Contrasena actual', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showCurrent = !_showCurrent))),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _newCtrl, obscureText: !_showNew,
              decoration: InputDecoration(labelText: 'Nueva contrasena', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showNew = !_showNew))),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v.length < 6) return 'Minimo 6 caracteres';
                return null;
              }),
          const SizedBox(height: 16),
          TextFormField(controller: _confirmCtrl, obscureText: !_showConfirm,
              decoration: InputDecoration(labelText: 'Confirmar contrasena', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showConfirm = !_showConfirm))),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v != _newCtrl.text) return 'Las contrasenas no coinciden';
                return null;
              }),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
              child: ElevatedButton(onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Actualizar Contrasena'))),
        ])),
      ),
    );
  }
}