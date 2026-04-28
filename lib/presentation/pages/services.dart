import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.get(ApiConstants.services);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _services = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar servicios');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteService(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar este servicio?'),
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
    if (confirm != true) return;
    try {
      final response = await ApiService.delete('${ApiConstants.services}/$id');
      if (response.statusCode == 200) {
        SnackBarHelper.showSuccess(context, 'Servicio eliminado');
        _loadServices();
      } else {
        final err = jsonDecode(response.body);
        SnackBarHelper.showError(
            context, err['error']?.toString() ?? 'Error al eliminar');
      }
    } catch (e) {
      SnackBarHelper.showError(context, e.toString());
    }
  }

  void _viewService(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Servicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Nombre:', service['name'] ?? service['nombre'] ?? ''),
            _detailRow('Precio:',
                '\$${(service['price'] ?? service['precio'] ?? 0).toString()}'),
            _detailRow('Duración:',
                '${service['duration'] ?? service['duracion'] ?? '-'} min'),
            if ((service['description'] ?? service['descripcion']) != null)
              _detailRow('Descripción:',
                  service['description'] ?? service['descripcion'] ?? ''),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.muted)),
        ),
        Expanded(child: Text(value)),
      ]),
    );
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
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline,
                size: 60, color: AppTheme.destructive),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadServices, child: const Text('Reintentar')),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateServiceScreen()),
          );
          if (created == true) _loadServices();
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadServices,
              child: _services.isEmpty
                  ? const Center(
                      child: Text('No hay servicios registrados',
                          style: TextStyle(color: AppTheme.muted)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _services.length,
                      itemBuilder: (_, i) => _buildServiceCard(_services[i]),
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
        const Text('Servicios',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text('${_services.length} servicios disponibles',
            style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ]),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final name = service['name'] ?? service['nombre'] ?? 'Sin nombre';
    final price = (service['price'] ?? service['precio'] ?? 0).toString();
    final duration = service['duration'] ?? service['duracion'];
    final id = service['id'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 5,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.spa_outlined, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Row(children: [
              Text('\$$price',
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
              if (duration != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.access_time, size: 13, color: AppTheme.muted),
                const SizedBox(width: 3),
                Text('$duration min',
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.muted)),
              ],
            ]),
          ]),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined,
                color: AppTheme.primary),
            onPressed: () => _viewService(service),
            tooltip: 'Ver',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => EditServiceScreen(service: service)),
              );
              if (updated == true) _loadServices();
            },
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.destructive),
            onPressed: () => _deleteService(id),
            tooltip: 'Eliminar',
          ),
        ]),
      ]),
    );
  }
}

// ── CREAR SERVICIO ────────────────────────────────────────────────────────────
class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});
  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final response = await ApiService.post(ApiConstants.services, {
        'name': _nameCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'duration': int.tryParse(_durationCtrl.text) ?? 0,
        'description': _descCtrl.text.trim(),
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Servicio creado exitosamente');
        Navigator.pop(context, true);
      } else {
        final err = jsonDecode(response.body);
        SnackBarHelper.showError(
            context, err['error']?.toString() ?? 'Error al crear servicio');
      }
    } catch (e) {
      SnackBarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Servicio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre *', prefixIcon: Icon(Icons.spa_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Precio *', prefixIcon: Icon(Icons.attach_money)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Duración (min)',
                  prefixIcon: Icon(Icons.access_time)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description_outlined)),
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
                    : const Text('Crear Servicio'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── EDITAR SERVICIO ───────────────────────────────────────────────────────────
class EditServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  const EditServiceScreen({super.key, required this.service});
  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _descCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.service['name'] ?? widget.service['nombre'] ?? '');
    _priceCtrl = TextEditingController(
        text: (widget.service['price'] ?? widget.service['precio'] ?? '')
            .toString());
    _durationCtrl = TextEditingController(
        text: (widget.service['duration'] ?? widget.service['duracion'] ?? '')
            .toString());
    _descCtrl = TextEditingController(
        text: widget.service['description'] ??
            widget.service['descripcion'] ??
            '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final id = widget.service['id'] as int;
      final response = await ApiService.put('${ApiConstants.services}/$id', {
        'name': _nameCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'duration': int.tryParse(_durationCtrl.text) ?? 0,
        'description': _descCtrl.text.trim(),
      });
      if (response.statusCode == 200) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Servicio actualizado');
        Navigator.pop(context, true);
      } else {
        final err = jsonDecode(response.body);
        SnackBarHelper.showError(
            context, err['error']?.toString() ?? 'Error al actualizar');
      }
    } catch (e) {
      SnackBarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Servicio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre *', prefixIcon: Icon(Icons.spa_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Precio *', prefixIcon: Icon(Icons.attach_money)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Duración (min)',
                  prefixIcon: Icon(Icons.access_time)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description_outlined)),
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
