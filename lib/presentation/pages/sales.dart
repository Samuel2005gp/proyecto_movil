import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/models/sale_model.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});
  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  List<SaleModel> _sales = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _totalToday = 0;
  double _totalMonth = 0;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.get(ApiConstants.sales);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _sales = data.map((j) => SaleModel.fromJson(j)).toList();
          _calculateTotals();
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar ventas');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateTotals() {
    final now = DateTime.now();
    _totalToday = 0;
    _totalMonth = 0;
    for (final sale in _sales) {
      if (sale.fecha.year == now.year &&
          sale.fecha.month == now.month &&
          sale.fecha.day == now.day) {
        _totalToday += sale.total;
      }
      if (sale.fecha.year == now.year && sale.fecha.month == now.month) {
        _totalMonth += sale.total;
      }
    }
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
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline,
              size: 60, color: AppTheme.destructive),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadSales, child: const Text('Reintentar')),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateSaleScreen()),
          );
          if (created == true) _loadSales();
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSales,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildSalesList(),
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
        const Text('Ventas',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text('${_sales.length} transacciones',
            style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ]),
    );
  }

  Widget _buildSummaryCards() {
    return Row(children: [
      Expanded(
          child: _buildSummaryCard(
              Icons.today, 'Hoy', '\$${_totalToday.toStringAsFixed(0)}')),
      const SizedBox(width: 12),
      Expanded(
          child: _buildSummaryCard(Icons.calendar_month, 'Este mes',
              '\$${_totalMonth.toStringAsFixed(0)}')),
    ]);
  }

  Widget _buildSummaryCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        Icon(icon, color: AppTheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildSalesList() {
    if (_sales.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No hay ventas registradas',
              style: TextStyle(color: AppTheme.muted)),
        ),
      );
    }
    return Column(children: _sales.map((s) => _buildSaleCard(s)).toList());
  }

  Widget _buildSaleCard(SaleModel sale) {
    final statusColor = _getStatusColor(sale.estado);
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long,
                color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(sale.clienteNombre,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                Text(sale.servicioNombre,
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.muted)),
                Text(_formatDate(sale.fecha),
                    style:
                        const TextStyle(fontSize: 11, color: AppTheme.muted)),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${sale.total.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 16)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(sale.estado,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ]),
        if (sale.metodoPago.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.payment, size: 14, color: AppTheme.muted),
            const SizedBox(width: 4),
            Text(_capitalize(sale.metodoPago),
                style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            if (sale.descuento > 0) ...[
              const SizedBox(width: 12),
              const Icon(Icons.discount_outlined,
                  size: 14, color: AppTheme.muted),
              const SizedBox(width: 4),
              Text('Desc: \$${sale.descuento.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            ],
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined,
                    color: AppTheme.primary),
                onPressed: () => _viewSale(sale),
                tooltip: 'Ver detalles',
              ),
            ],
          ),
        ],
      ]),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
        return AppTheme.colorSuccess;
      case 'completada':
        return AppTheme.colorSuccess;
      case 'pendiente':
        return AppTheme.colorEdit;
      case 'cancelada':
        return AppTheme.destructive;
      default:
        return AppTheme.muted;
    }
  }

  void _viewSale(SaleModel sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Venta'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Cliente:', sale.clienteNombre),
              _buildDetailRow('Servicio:', sale.servicioNombre),
              _buildDetailRow('Fecha:', _formatDate(sale.fecha)),
              _buildDetailRow('Método de Pago:', sale.metodoPago),
              _buildDetailRow(
                  'Subtotal:', '\$${sale.subtotal.toStringAsFixed(0)}'),
              if (sale.descuento > 0)
                _buildDetailRow(
                    'Descuento:', '\$${sale.descuento.toStringAsFixed(0)}'),
              _buildDetailRow('Total:', '\$${sale.total.toStringAsFixed(0)}'),
              _buildDetailRow('Estado:', sale.estado),
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
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.muted,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ── CREAR VENTA ──────────────────────────────────────────────────────────────
class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});
  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  String _tipo = 'cita';
  bool _isSaving = false;
  bool _isLoadingData = true;

  List<Map<String, dynamic>> _citasDisponibles = [];
  Map<String, dynamic>? _citaSeleccionada;

  List<Map<String, dynamic>> _servicios = [];
  List<Map<String, dynamic>> _clientes = [];
  int? _clienteSeleccionado;
  final List<Map<String, dynamic>> _serviciosAgregados = [];
  int? _servicioSeleccionado;
  double _descuento = 0;

  String? _metodoPago;
  final List<String> _metodosPago = [
    'efectivo',
    'tarjeta',
    'transferencia',
    'nequi',
    'daviplata'
  ];
  final _descuentoCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descuentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final results = await Future.wait([
        ApiService.get(ApiConstants.salesAppointments),
        ApiService.get(ApiConstants.services),
        ApiService.get(ApiConstants.clients),
      ]);
      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body) as List;
        _citasDisponibles = data.cast<Map<String, dynamic>>();
      }
      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body) as List;
        _servicios = data
            .map((s) => {
                  'id': s['id'],
                  'name': s['name'] ?? s['nombre'] ?? '',
                  'price': (s['price'] ?? s['precio'] ?? 0).toDouble(),
                })
            .toList();
      }
      if (results[2].statusCode == 200) {
        final data = jsonDecode(results[2].body) as List;
        _clientes = data
            .map((c) => {
                  'id': c['id'] ?? c['PK_id_cliente'],
                  'name':
                      '${c['nombre'] ?? c['firstName'] ?? ''} ${c['apellido'] ?? c['lastName'] ?? ''}'
                          .trim(),
                })
            .toList();
      }
    } catch (_) {}
    setState(() => _isLoadingData = false);
  }

  double get _subtotal {
    if (_tipo == 'cita' && _citaSeleccionada != null) {
      return (_citaSeleccionada!['price'] ?? 0).toDouble();
    }
    return _serviciosAgregados.fold(
        0.0, (s, item) => s + (item['price'] as double));
  }

  double get _total => (_subtotal - _descuento).clamp(0, double.infinity);

  Future<void> _save() async {
    if (_metodoPago == null) {
      SnackBarHelper.showError(context, 'Selecciona un método de pago');
      return;
    }
    if (_tipo == 'cita' && _citaSeleccionada == null) {
      SnackBarHelper.showError(context, 'Selecciona una cita');
      return;
    }
    if (_tipo == 'directo' && _serviciosAgregados.isEmpty) {
      SnackBarHelper.showError(context, 'Agrega al menos un servicio');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{
        'tipo': _tipo,
        'metodoPago': _metodoPago,
        'descuento': _descuento,
      };

      if (_tipo == 'cita') {
        body['citaId'] = _citaSeleccionada!['id'];
      } else {
        if (_clienteSeleccionado != null) {
          body['clienteId'] = _clienteSeleccionado;
        }
        body['servicios'] = _serviciosAgregados
            .map((s) => {
                  'id': s['id'],
                  'precio': s['price'],
                  'qty': 1,
                })
            .toList();
      }

      final response = await ApiService.post(ApiConstants.sales, body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Venta registrada exitosamente');
        Navigator.pop(context, true);
      } else {
        final err = jsonDecode(response.body);
        SnackBarHelper.showError(
            context, err['error']?.toString() ?? 'Error al registrar venta');
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
      appBar: AppBar(title: const Text('Nueva Venta')),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de venta *',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: _buildTipoBtn(
                              'cita', 'Desde cita', Icons.calendar_today)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildTipoBtn(
                              'directo', 'Venta directa', Icons.point_of_sale)),
                    ]),
                    const SizedBox(height: 20),
                    if (_tipo == 'cita') ...[
                      const Text('Cita *',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _citaSeleccionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            hintText: 'Selecciona una cita'),
                        items: _citasDisponibles
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    '${c['clientName']} — ${c['service']} (${c['date']})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _citaSeleccionada = v),
                      ),
                      if (_citaSeleccionada != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Cliente: ${_citaSeleccionada!['clientName']}',
                                    style: const TextStyle(fontSize: 13)),
                                Text(
                                    'Servicio: ${_citaSeleccionada!['service']}',
                                    style: const TextStyle(
                                        fontSize: 13, color: AppTheme.muted)),
                                Text(
                                    'Precio: \$${(_citaSeleccionada!['price'] ?? 0).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ]),
                        ),
                      ],
                    ] else ...[
                      const Text('Cliente (opcional)',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _clienteSeleccionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            hintText: 'Selecciona un cliente'),
                        items: _clientes
                            .map((c) => DropdownMenuItem<int>(
                                  value: c['id'] as int,
                                  child: Text(c['name'],
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _clienteSeleccionado = v),
                      ),
                      const SizedBox(height: 20),
                      const Text('Servicios *',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _servicioSeleccionado,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                hintText: 'Selecciona servicio'),
                            items: _servicios
                                .map((s) => DropdownMenuItem<int>(
                                      value: s['id'] as int,
                                      child: Text(
                                          '${s['name']} — \$${(s['price'] as double).toStringAsFixed(0)}',
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _servicioSeleccionado = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_servicioSeleccionado == null) return;
                            final s = _servicios.firstWhere(
                                (x) => x['id'] == _servicioSeleccionado);
                            setState(() {
                              _serviciosAgregados.add({...s});
                              _servicioSeleccionado = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(14)),
                          child: const Icon(Icons.add),
                        ),
                      ]),
                      if (_serviciosAgregados.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._serviciosAgregados
                            .asMap()
                            .entries
                            .map((e) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.check_circle,
                                      color: AppTheme.colorSuccess, size: 18),
                                  title: Text(e.value['name'],
                                      style: const TextStyle(fontSize: 13)),
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                            '\$${(e.value['price'] as double).toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.close,
                                              size: 16,
                                              color: AppTheme.destructive),
                                          onPressed: () => setState(() =>
                                              _serviciosAgregados
                                                  .removeAt(e.key)),
                                        ),
                                      ]),
                                )),
                      ],
                    ],
                    const SizedBox(height: 20),
                    const Text('Descuento (\$)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descuentoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.discount_outlined)),
                      onChanged: (v) =>
                          setState(() => _descuento = double.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: 20),
                    const Text('Método de pago *',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _metodoPago,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          hintText: 'Selecciona método de pago'),
                      items: _metodosPago
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child:
                                    Text(m[0].toUpperCase() + m.substring(1)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _metodoPago = v),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(children: [
                        _buildResumenRow(
                            'Subtotal', '\$${_subtotal.toStringAsFixed(0)}'),
                        if (_descuento > 0)
                          _buildResumenRow('Descuento',
                              '-\$${_descuento.toStringAsFixed(0)}',
                              color: AppTheme.colorSuccess),
                        const Divider(),
                        _buildResumenRow(
                            'Total', '\$${_total.toStringAsFixed(0)}',
                            bold: true, color: AppTheme.primary),
                      ]),
                    ),
                    const SizedBox(height: 32),
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
                              : const Text('Registrar Venta'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ]),
            ),
    );
  }

  Widget _buildTipoBtn(String tipo, String label, IconData icon) {
    final selected = _tipo == tipo;
    return GestureDetector(
      onTap: () => setState(() {
        _tipo = tipo;
        _citaSeleccionada = null;
        _serviciosAgregados.clear();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: selected ? Colors.white : AppTheme.muted),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.foreground,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
        ]),
      ),
    );
  }

  Widget _buildResumenRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                color: AppTheme.muted,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppTheme.foreground,
              fontSize: bold ? 16 : 14,
            )),
      ]),
    );
  }
}
