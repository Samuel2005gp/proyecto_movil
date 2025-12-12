import 'package:flutter/material.dart';

class SaleScreen extends StatelessWidget {
   SaleScreen({super.key});
  final List<Map<String, dynamic>> sales = [
    {
      "name": "Ana Martínez",
      "service": "Masaje Relajante",
      "time": "10:00 AM",
      "method": "Tarjeta",
      "price": 45,
      "status": "Pagado",
      "statusColor": Color(0xFFB7EED5),
      "statusTextColor": Color(0xFF1E9E6A),
    },
    {
      "name": "Carlos López",
      "service": "Facial Hidratante + Manicure",
      "time": "11:30 AM",
      "method": "Efectivo",
      "price": 75,
      "status": "Pagado",
      "statusColor": Color(0xFFB7EED5),
      "statusTextColor": Color(0xFF1E9E6A),
    },
    {
      "name": "Laura Pérez",
      "service": "Pedicure Spa",
      "time": "2:00 PM",
      "method": "Tarjeta",
      "price": 35,
      "status": "Pendiente",
      "statusColor": Color(0xFFFFE1C2),
      "statusTextColor": Color(0xFFC67A2E),
    },
    {
      "name": "Diego Ramírez",
      "service": "Masaje Terapéutico",
      "time": "3:30 PM",
      "method": "Transferencia",
      "price": 65,
      "status": "Pagado",
      "statusColor": Color(0xFFB7EED5),
      "statusTextColor": Color(0xFF1E9E6A),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(),
            const SizedBox(height: 25),
            _summaryCards(),
            const SizedBox(height: 20),
            _filterButtons(),
            const SizedBox(height: 20),
            _salesList(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFADEBD3), Color(0xFF86DDBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Ventas",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "3 transacciones hoy",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.teal.shade700),
          ),
        ],
      ),
    );
  }

  // ---------------- SUMMARY CARDS ----------------
  Widget _summaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _summaryCard(Icons.attach_money, "Hoy", "\$155"),
        _summaryCard(Icons.trending_up, "Este mes", "\$345"),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Color(0xD9FFFFFF), // white con 85% opacity
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal, size: 30),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey)),
            SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FILTER + EXPORT BUTTONS ----------------
  Widget _filterButtons() {
    return Row(
      children: [
        Expanded(child: _roundedButton(Icons.filter_list, "Filtrar")),
        SizedBox(width: 10),
        Expanded(child: _roundedButton(Icons.upload, "Exportar")),
      ],
    );
  }

  Widget _roundedButton(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ---------------- SALES LIST ----------------
  Widget _salesList() {
    return Column(children: sales.map((s) => _saleCard(s)).toList());
  }

  Widget _saleCard(Map<String, dynamic> sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Icon avatar
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFE1F3EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag, color: Colors.teal, size: 28),
          ),

          SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale["name"],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  sale["service"],
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                SizedBox(height: 4),
                Text(
                  "${sale["time"]}   •   ${sale["method"]}",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Price + status
          Column(
            children: [
              Text(
                "\$${sale["price"]}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sale["statusColor"],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sale["status"],
                  style: TextStyle(
                    color: sale["statusTextColor"],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
