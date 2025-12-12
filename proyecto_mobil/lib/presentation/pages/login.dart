import 'package:flutter/material.dart';
import 'admin_home.dart';
import 'cliente_home.dart';
import 'empleado_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();

  void login() {
    final e = email.text.trim();
    final p = pass.text.trim();

    if (e == "admin@gmail.com" && p == "123") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminHome()));
    } else if (e == "cliente@gmail.com" && p == "123") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ClienteHome()));
    } else if (e == "empleado@gmail.com" && p == "123") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const EmpleadoHome()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Credenciales incorrectas")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 1, 137, 76), Color.fromARGB(255, 3, 156, 118)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            width: 330,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_pin, size: 95, color: Colors.teal),

                const SizedBox(height: 10),

                const Text(
                  "Iniciar Sesión",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),

                const SizedBox(height: 25),

                _inputField(
                    controller: email,
                    label: "Correo",
                    icon: Icons.email_outlined),

                const SizedBox(height: 15),

                _inputField(
                    controller: pass,
                    label: "Contraseña",
                    icon: Icons.lock_outline,
                    isPassword: true),

                const SizedBox(height: 25),

                ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 60),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text(
                    "Entrar",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        hintStyle: const TextStyle(color: Colors.black45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
