import 'package:flutter/material.dart';

class ClientScreen extends StatelessWidget {
  const ClientScreen({super.key});

  static const List<Map<String, dynamic>> frequentClients = [
    {"initials": "IV", "name": "Isabel"},
    {"initials": "MG", "name": "María"},
    {"initials": "MÁC", "name": "Miguel"},
    {"initials": "JH", "name": "Juan"},
  ];

  static const List<Map<String, dynamic>> clients = [
    {
      "initials": "AM",
      "name": "Ana Martínez",
      "visits": 14,
      "email": "ana@gmail.com",
      "phone": "3001234567"
    },
    {
      "initials": "CL",
      "name": "Carlos López",
      "visits": 2,
      "email": "carlos@gmail.com",
      "phone": "3009876543"
    },
    {
      "initials": "LP",
      "name": "Laura Pérez",
      "visits": 8,
      "email": "laura@gmail.com",
      "phone": "3011112222"
    },
    {
      "initials": "DR",
      "name": "Diego Ramírez",
      "visits": 1,
      "email": "diego@gmail.com",
      "phone": "3024445566"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F9FA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ClientScreenBody(),
        ),
      ),
    );
  }
}

class ClientScreenBody extends StatelessWidget {
  const ClientScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ClientHeader(),
        SizedBox(height: 20),
        SearchBarClients(),
        SizedBox(height: 20),
        FrequentClientsSection(),
        SizedBox(height: 20),
        ClientListSection(),
        SizedBox(height: 60),
      ],
    );
  }
}

// ---------------- HEADER ----------------

class ClientHeader extends StatelessWidget {
  const ClientHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFADEBD3), Color(0xFF86DDBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Clientes",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "50 clientes registrados",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ---------------- SEARCH BAR ----------------

class SearchBarClients extends StatelessWidget {
  const SearchBarClients({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Buscar clientes...",
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }
}

// ---------------- FREQUENT CLIENTS ----------------

class FrequentClientsSection extends StatelessWidget {
  const FrequentClientsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Clientes Frecuentes",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ClientScreen.frequentClients
              .map((c) => FrequentClientItem(client: c))
              .toList(),
        )
      ],
    );
  }
}

class FrequentClientItem extends StatelessWidget {
  final Map<String, dynamic> client;
  const FrequentClientItem({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF1E9E6A),
          child: Text(
            client["initials"],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          client["name"],
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

// ---------------- CLIENT LIST ----------------

class ClientListSection extends StatelessWidget {
  const ClientListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ClientScreen.clients
          .map((c) => ClientCard(client: c))
          .toList(),
    );
  }
}

class ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;
  const ClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFDFF4EB),
            child: Text(
              client["initials"],
              style: const TextStyle(color: Colors.teal),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client["name"],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${client["visits"]} visitas",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (_) => ClientDetailCard(client: client),
              );
            },
            child: const Icon(Icons.more_horiz, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ---------------- BOTTOM CARD ----------------

class ClientDetailCard extends StatelessWidget {
  final Map<String, dynamic> client;
  const ClientDetailCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            client["name"],
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 15),
          _dataTile(Icons.email, "Email", client["email"]),
          _dataTile(Icons.phone, "Teléfono", client["phone"]),
          _dataTile(Icons.history, "Visitas", "${client["visits"]}"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _dataTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 10),
          Text("$title: $value",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
