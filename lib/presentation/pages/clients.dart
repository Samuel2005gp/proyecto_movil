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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadClients,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: _filteredClients.isEmpty
                      ? const Center(
                          child: Text('No se encontraron clientes',
                              style: TextStyle(color: AppTheme.muted)))
                      : ListView.builder(
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) =>
                              _buildClientCard(_filteredClients[index]),
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
          const Text('Clientes',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 5),
          Text('${_clients.length} clientes registrados',
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
                icon: const Icon(Icons.visibility_outlined,
                    color: AppTheme.primary),
                onPressed: () => _viewClient(client),
                tooltip: 'Ver detalles',
              ),
              // Botón Editar
              IconButton(
                icon:
                    const Icon(Icons.edit_outlined, color: AppTheme.colorEdit),
                onPressed: () => _editClient(client),
                tooltip: 'Editar',
              ),
              // Botón Eliminar
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
    // Por ahora mostrar un mensaje, luego se puede implementar la edición completa
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Cliente'),
        content: const Text(
            'Funcionalidad de edición en desarrollo.\n\nPróximamente podrás editar la información del cliente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
