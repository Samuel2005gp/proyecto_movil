import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/models/user_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService.get(ApiConstants.users),
        ApiService.get(ApiConstants.userRoles),
      ]);

      final usersRes = results[0];
      final rolesRes = results[1];

      if (usersRes.statusCode == 200) {
        final List<dynamic> data = jsonDecode(usersRes.body);
        _users = data.map((j) => UserModel.fromJson(j)).toList();
        _filtered = _users;
      }

      if (rolesRes.statusCode == 200) {
        final List<dynamic> data = jsonDecode(rolesRes.body);
        _roles = data.cast<Map<String, dynamic>>();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users
              .where((u) =>
                  u.nombreCompleto.toLowerCase().contains(q) ||
                  u.correo.toLowerCase().contains(q) ||
                  u.rol.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _toggleStatus(UserModel user) async {
    try {
      final response = await ApiService.patch(
        ApiConstants.userStatus(user.id),
        {'isActive': !user.isActive},
      );
      if (response.statusCode == 200) {
        _showSuccess(
            user.isActive ? 'Usuario desactivado' : 'Usuario activado');
        _loadData();
      } else {
        throw Exception('Error al cambiar estado');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirm = await _showConfirmDialog('¿Eliminar este usuario?');
    if (!confirm) return;
    try {
      final response = await ApiService.delete(ApiConstants.userDetail(id));
      if (response.statusCode == 200) {
        _showSuccess('Usuario eliminado');
        _loadData();
      } else {
        throw Exception('Error al eliminar');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showSuccess(String msg) => SnackBarHelper.showSuccess(context, msg);

  void _showError(String msg) => SnackBarHelper.showError(context, msg);

  void _viewUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Usuario'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre:', user.nombreCompleto),
              _buildDetailRow('Email:', user.correo),
              _buildDetailRow('Teléfono:',
                  user.telefono.isNotEmpty ? user.telefono : 'No registrado'),
              _buildDetailRow('Rol:', user.rol),
              _buildDetailRow('Estado:', user.isActive ? 'Activo' : 'Inactivo'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editUser(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormScreen(user: user, roles: _roles),
      ),
    ).then((updated) {
      if (updated == true) _loadData();
    });
  }

  Future<bool> _showConfirmDialog(String msg) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary)));
    }

    if (_errorMessage != null) {
      return Scaffold(
          body: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 60, color: AppTheme.destructive),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
        ],
      )));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => UserFormScreen(roles: _roles),
            ),
          );
          if (created == true) _loadData();
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text('No se encontraron usuarios',
                              style: TextStyle(color: AppTheme.muted)))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildUserCard(_filtered[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usuarios',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text('${_users.length} usuarios registrados',
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre, correo o rol...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: AppTheme.muted),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final initials = user.nombre.isNotEmpty
        ? (user.apellido.isNotEmpty
            ? '${user.nombre[0]}${user.apellido[0]}'.toUpperCase()
            : user.nombre[0].toUpperCase())
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: user.isActive
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.muted.withOpacity(0.2),
                child: Text(initials,
                    style: TextStyle(
                        color:
                            user.isActive ? AppTheme.primary : AppTheme.muted,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.nombreCompleto,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(user.correo,
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildChip(user.rol, AppTheme.colorPurple),
                        const SizedBox(width: 6),
                        _buildChip(
                          user.isActive ? 'Activo' : 'Inactivo',
                          user.isActive
                              ? AppTheme.colorSuccess
                              : AppTheme.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined,
                    color: AppTheme.primary),
                onPressed: () => _viewUser(user),
                tooltip: 'Ver detalles',
              ),
              // Botón Editar
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                onPressed: () => _editUser(user),
                tooltip: 'Editar',
              ),
              // Botón Activar/Desactivar
              IconButton(
                icon: Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  color: user.isActive ? AppTheme.muted : AppTheme.colorSuccess,
                ),
                onPressed: () => _toggleStatus(user),
                tooltip: user.isActive ? 'Desactivar' : 'Activar',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.destructive),
                onPressed: () => _deleteUser(user.id),
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  FORMULARIO CREAR / EDITAR USUARIO
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class UserFormScreen extends StatefulWidget {
  final UserModel? user;
  final List<Map<String, dynamic>> roles;

  const UserFormScreen({super.key, this.user, required this.roles});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _documentCtrl;
  String? _selectedRole;
  String? _selectedDocType;
  bool _isSaving = false;
  bool _showPassword = false;

  static const _docTypes = ['CC', 'TI', 'CE', 'Pasaporte', 'NIT'];

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.user?.nombre ?? '');
    _apellidoCtrl = TextEditingController(text: widget.user?.apellido ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.correo ?? '');
    _telefonoCtrl = TextEditingController(text: widget.user?.telefono ?? '');
    _passwordCtrl = TextEditingController();
    _documentCtrl = TextEditingController(text: widget.user?.document ?? '');
    _selectedRole = widget.user?.rol;
    _selectedDocType = widget.user?.documentType.isNotEmpty == true
        ? widget.user!.documentType
        : null;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _documentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final body = <String, dynamic>{
        'firstName': _nombreCtrl.text.trim(),
        'lastName': _apellidoCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _telefonoCtrl.text.trim(),
        'role': _selectedRole,
        if (_selectedDocType != null) 'documentType': _selectedDocType,
        if (_documentCtrl.text.trim().isNotEmpty)
          'document': _documentCtrl.text.trim(),
        if (!_isEditing && _passwordCtrl.text.isNotEmpty)
          'password': _passwordCtrl.text,
      };

      final response = _isEditing
          ? await ApiService.put(ApiConstants.userDetail(widget.user!.id), body)
          : await ApiService.post(ApiConstants.users, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(
            context,
            _isEditing
                ? 'Usuario actualizado correctamente'
                : 'Usuario creado correctamente');
        Navigator.pop(context, true);
      } else {
        final error = jsonDecode(response.body);
        final msg = error['error']?.toString() ??
            error['message']?.toString() ??
            'Error al guardar';
        SnackBarHelper.showError(context, msg);
      }
    } catch (e) {
      SnackBarHelper.showError(
          context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_isEditing ? 'Editar Usuario' : 'Nuevo Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // Nombre
            TextFormField(
              controller: _nombreCtrl,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
              ],
              decoration: const InputDecoration(
                  labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'El nombre es obligatorio';
                if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Apellido
            TextFormField(
              controller: _apellidoCtrl,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
              ],
              decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.person_2_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'El apellido es obligatorio';
                if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Email — editable siempre
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'El correo es obligatorio';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()))
                  return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Teléfono
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\s]')),
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 7) return 'Mínimo 7 dígitos';
                if (digits.length > 15) return 'Máximo 15 dígitos';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Tipo de documento
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
            // Número de documento
            TextFormField(
              controller: _documentCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: const InputDecoration(
                  labelText: 'Número de documento',
                  prefixIcon: Icon(Icons.numbers_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (v.replaceAll(RegExp(r'\D'), '').length < 5) {
                  return 'Mínimo 5 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Rol
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.manage_accounts_outlined)),
              items: widget.roles.map((role) {
                final name = role['name']?.toString() ??
                    role['nombre']?.toString() ??
                    '';
                return DropdownMenuItem(value: name, child: Text(name));
              }).toList(),
              onChanged: (v) => setState(() => _selectedRole = v),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Selecciona un rol' : null,
            ),
            const SizedBox(height: 16),
            // Contraseña (solo al crear)
            if (!_isEditing)
              TextFormField(
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (v) {
                  if (!_isEditing && (v == null || v.isEmpty)) {
                    return 'Requerido';
                  }
                  if (v != null && v.isNotEmpty && v.trim().length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
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
                    : Text(_isEditing ? 'Guardar Cambios' : 'Crear Usuario'),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
