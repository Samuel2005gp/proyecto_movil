import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Map<String, String>>> _appointments = {
    DateTime(2025, 11, 28): [
      {"name": "Ana Martínez", "service": "Masaje Relajante", "time": "10:00 AM"},
      {"name": "Carlos López", "service": "Facial Hidratante", "time": "11:30 AM"},
    ]
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Map<String, String>> _getAppointmentsOfDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _appointments[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F6F6),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAppointmentDialog,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.teal, size: 28),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 20),
              _calendarCard(),

              const SizedBox(height: 32),

              _dayAppointments(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Citas",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(
          "${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _calendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffA1E5C1), Color(0xff77D9B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,

          enabledDayPredicate: (day) {
            return !day.isBefore(
              DateTime.now().subtract(const Duration(days: 1)),
            );
          },

          selectedDayPredicate: (day) =>
              day.year == _selectedDay!.year &&
              day.month == _selectedDay!.month &&
              day.day == _selectedDay!.day,

          availableCalendarFormats: const {
            CalendarFormat.month: 'Mes',
          },

          eventLoader: _getAppointmentsOfDay,

          calendarStyle: CalendarStyle(
            disabledTextStyle: TextStyle(color: Colors.grey.shade400),
            markersMaxCount: 3,
            markerDecoration: const BoxDecoration(
              color: Color.fromARGB(255, 10, 111, 242),
              shape: BoxShape.circle,
            ),
          ),

          calendarBuilders: CalendarBuilders(
            selectedBuilder: (context, date, _) {
              return Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${date.day}",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              );
            },

            todayBuilder: (context, date, _) {
              return Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade200,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${date.day}",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              );
            },
          ),

          onDaySelected: (selected, focused) {
            if (selected.isBefore(
              DateTime.now().subtract(const Duration(days: 1)),
            )) {
              return;
            }

            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
        ),
      ),
    );
  }

  Widget _dayAppointments() {
    final list = _getAppointmentsOfDay(_selectedDay!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Próximas Citas - ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}",
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        if (list.isEmpty)
          const Text("No hay citas hoy")
        else
          ...list.map((appt) =>
              _appointmentCard(appt["name"]!, appt["service"]!, appt["time"]!)),
      ],
    );
  }

  Widget _appointmentCard(String name, String service, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F5EE),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.access_time, color: Colors.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(service,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
                color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // NUEVA CITA - AHORA CON VALIDACIÓN DE HORARIO
  // ---------------------------
  void _showAddAppointmentDialog() {
    final nameController = TextEditingController();
    final serviceController = TextEditingController();

    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Nueva cita"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nombre"),
                  ),
                  TextField(
                    controller: serviceController,
                    decoration: const InputDecoration(labelText: "Servicio"),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (picked != null) {
                        // Validación de horario permitido
                        final double time =
                            picked.hour + picked.minute / 60;

                        if (time < 9 || time > 16.5) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Las citas solo pueden ser entre 9:00 AM y 4:30 PM'),
                            ),
                          );
                          return;
                        }

                        setState(() => selectedTime = picked);
                      }
                    },
                    child: Text(
                      selectedTime == null
                          ? "Seleccionar hora"
                          : selectedTime!.format(context),
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final service = serviceController.text.trim();
                    if (name.isEmpty || service.isEmpty || selectedTime == null)
                      return;

                    final key = DateTime(
                      _selectedDay!.year,
                      _selectedDay!.month,
                      _selectedDay!.day,
                    );

                    setState(() {
                      _appointments.putIfAbsent(key, () => []);
                      _appointments[key]!.add({
                        "name": name,
                        "service": service,
                        "time": selectedTime!.format(context),
                      });
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
