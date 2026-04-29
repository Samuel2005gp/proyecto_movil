import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/models/client_model.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get(ApiConstants.clients);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _clients = data.map((json) => ClientModel.fromJson(json)).toList();
          _filteredClients = _clients;
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar clientes');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = query.isEmpty
          ? _clients
          : _clients.where((c) {
              return c.nombreCompleto.toLowerCase().contains(query) ||
                  c.correo.toLowerCase().contains(query) ||
                  c.telefono.contains(query);
            }).toList();
    });
  }

  Future<void> _deleteClient(int id) async {
    final confirm = await _showConfirmDialog('Â¿Eliminar este cliente?');
    if (!confirm) return;
    try {
      final response = await ApiService.delete(ApiConstants.clientDetail(id));
      if (response.statusCode == 200) {
        _showSuccess('Cliente eliminado');
        _loadClients();
      } else {
        throw Exception('Error al eliminar');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showSuccess(String msg) => SnackBarHelper.showSuccess(context, msg);
  void _showError(String msg) => SnackBarHelper.showError(context, msg);

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(message),
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
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
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
              ElevatedButton(
                  onPressed: _loadClients, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadClients,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildSearchBar(),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _filteredClients.isEmpty
                        ? const Center(
                            child: Text('No se encontraron clientes',
                                style: TextStyle(color: AppTheme.muted)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: _filteredClients.length,
                            itemBuilder: (context, index) =>
                                _buildClientCard(_filteredClients[index]),
                          ),
                  ),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Clientes',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text('${_clients.length} clientes registrados',
            style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar clientes...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: AppTheme.muted),
        ),
      ),
    );
  }

  Widget _buildClientCard(ClientModel client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 5,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: Text(
                  client.nombre.isNotEmpty && client.apellido.isNotEmpty
                      ? client.nombre[0].toUpperCase() +
                          client.apellido[0].toUpperCase()
                      : client.nombre.isNotEmpty
                          ? client.nombre[0].toUpperCase()
                          : '?',
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.nombreCompleto,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(client.correo,
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 13)),
                    if (client.telefono.isNotEmpty)
                      Text(client.telefono,
                          style: const TextStyle(
                              color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Botón Ver
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined,
                    color: AppTheme.primary),
                onPressed: () => _viewClient(client),
                tooltip: 'Ver detalles',
              ),
              // Botón Editar
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                onPressed: () => _editClient(client),
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.destructive),
                onPressed: () => _deleteClient(client.id),
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewClient(ClientModel client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Cliente'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre:', client.nombreCompleto),
              _buildDetailRow('Email:', client.correo),
              _buildDetailRow(
                  'Teléfono:',
                  client.telefono.isNotEmpty
                      ? client.telefono
                      : 'No registrado'),
              _buildDetailRow('Estado:', client.estado),
              if (client.tipoDocumento.isNotEmpty)
                _buildDetailRow('Tipo Doc:', client.tipoDocumento),
              if (client.numeroDocumento.isNotEmpty)
                _buildDetailRow('Documento:', client.numeroDocumento),
              if (client.direccion.isNotEmpty)
                _buildDetailRow('Dirección:', client.direccion),
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

  void _editClient(ClientModel client) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditClientScreen(client: client)),
    ).then((updated) {
      if (updated == true) _loadClients();
    });
  }
}

// ── EDITAR CLIENTE ────────────────────────────────────────────────────────────
class EditClientScreen extends StatefulWidget {
  final ClientModel client;
  const EditClientScreen({super.key, required this.client});
  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _correoCtrl;
  late TextEditingController _documentoCtrl;
  late TextEditingController _direccionCtrl;
  String? _tipoDocumento;
  bool _isSaving = false;

  static const _tiposDoc = [
    'CC',
    'TI',
    'CE',
    'Pasaporte',
    'NIT',
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.client.nombre);
    _apellidoCtrl = TextEditingController(text: widget.client.apellido);
    _telefonoCtrl = TextEditingController(text: widget.client.telefono);
    _correoCtrl = TextEditingController(text: widget.client.correo);
    _documentoCtrl = TextEditingController(text: widget.client.numeroDocumento);
    _direccionCtrl = TextEditingController(text: widget.client.direccion);
    _tipoDocumento = widget.client.tipoDocumento.isNotEmpty
        ? widget.client.tipoDocumento
        : null;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _documentoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final response = await ApiService.put(
        ApiConstants.clientDetail(widget.client.id),
        {
          'firstName': _nombreCtrl.text.trim(),
          'lastName': _apellidoCtrl.text.trim(),
          'phone': _telefonoCtrl.text.trim(),
          'email': _correoCtrl.text.trim(),
          'address': _direccionCtrl.text.trim(),
          if (_tipoDocumento != null) 'documentType': _tipoDocumento,
          if (_documentoCtrl.text.trim().isNotEmpty)
            'document': _documentoCtrl.text.trim(),
        },
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(
            context, 'Cliente actualizado correctamente');
        Navigator.pop(context, true);
      } else {
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final err = jsonDecode(response.body);
          errorMsg = err['error']?.toString() ??
              err['message']?.toString() ??
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
      appBar: AppBar(title: const Text('Editar Cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar con iniciales
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    widget.client.nombre.isNotEmpty
                        ? '${widget.client.nombre[0]}${widget.client.apellido.isNotEmpty ? widget.client.apellido[0] : ''}'
                            .toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 28,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tipo y número de documento en fila
              DropdownButtonFormField<String>(
                value: _tipoDocumento,
                decoration: const InputDecoration(
                    labelText: 'Tipo de Documento',
                    prefixIcon: Icon(Icons.badge_outlined)),
                items: _tiposDoc
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoDocumento = v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _documentoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Número de Documento',
                    prefixIcon: Icon(Icons.numbers_outlined)),
              ),
              const SizedBox(height: 16),

              // Nombre y apellido en fila
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apellidoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    prefixIcon: Icon(Icons.person_2_outlined)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Teléfono y email en fila
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Dirección
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'Calle 123 #45-67, Bogotá'),
              ),
              const SizedBox(height: 32),

              // Botones
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Actualizar Cliente'),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
