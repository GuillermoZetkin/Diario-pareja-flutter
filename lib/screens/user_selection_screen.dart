import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colores.dart';
import 'home_screen.dart';

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  Future<void> _seleccionarUsuario(BuildContext context, String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rol_usuario', rol); // Guarda 'Mariana' o 'Isael'

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, color: AppColores.rojoElla, size: 60),
            const SizedBox(height: 20),
            const Text(
              "¿Quién está usando la app?",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColores.azulTuyo),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // BOTÓN PARA MARIANA
            _buildBotonUsuario(
              context,
              nombre: "Mariana Samantha",
              color: AppColores.rojoElla,
              onTap: () => _seleccionarUsuario(context, 'Mariana'),
            ),

            const SizedBox(height: 20),

            // BOTÓN PARA ISAEL
            _buildBotonUsuario(
              context,
              nombre: "Isael Guillermo",
              color: AppColores.azulTuyo,
              onTap: () => _seleccionarUsuario(context, 'Isael'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonUsuario(BuildContext context,
      {required String nombre,
      required Color color,
      required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        child: Text(nombre, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
