import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
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
          _clients =
              data.map((json) => ClientModel.fromJson(json)).toList();
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
      final response =
          await ApiService.delete(ApiConstants.clientDetail(id));
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

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.colorSuccess),
      );

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.destructive),
      );

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
                  onPressed: _loadClients,
                  child: const Text('Reintentar')),
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
      child: Row(
        children: [
            CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            child: Text(
              client.nombre.isNotEmpty && client.apellido.isNotEmpty
                  ? client.nombre[0].toUpperCase() + client.apellido[0].toUpperCase()
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
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showClientDetail(client),
            child: const Icon(Icons.more_horiz, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  void _showClientDetail(ClientModel client) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text(client.nombreCompleto,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 15),
            _buildInfoTile(Icons.email, 'Email', client.correo),
            _buildInfoTile(Icons.phone, 'Teléfono', client.telefono),
            _buildInfoTile(
                Icons.check_circle, 'Estado', client.estado),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showError('Edición próximamente');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colorEdit),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteClient(client.id);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.destructive),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text('$title: ',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500)),
          Expanded(
              child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}


