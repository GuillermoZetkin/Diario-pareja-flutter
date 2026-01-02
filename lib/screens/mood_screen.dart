import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para saber quién soy
import '../utils/colores.dart';

class MoodScreen extends StatelessWidget {
  const MoodScreen({super.key});

  final List<Map<String, String>> estados = const [
    {'emoji': '😊', 'nombre': 'Feliz'},
    {'emoji': '😴', 'nombre': 'Cansada/o'},
    {'emoji': '🏥', 'nombre': 'En Guardia'},
    {'emoji': '🩺', 'nombre': 'Estudiando'},
    {'emoji': '🥺', 'nombre': 'Te extraño'},
    {'emoji': '🍕', 'nombre': 'Con hambre'},
    {'emoji': '☕', 'nombre': 'Necesito café'},
    {'emoji': '✨', 'nombre': 'Día libre'},
  ];

  Future<void> _actualizarEstado(
      BuildContext context, Map<String, String> estado) async {
    // 1. Obtener quién soy desde memoria
    final prefs = await SharedPreferences.getInstance();
    final String miNombre = prefs.getString('rol_usuario') ?? "Usuario";

    if (Platform.isLinux) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Simulación: $miNombre está ${estado['nombre']}")),
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      return;
    }

    try {
      // 2. Guardar en Firebase bajo MI nombre (en minúsculas para evitar errores)
      await FirebaseFirestore.instance
          .collection('estados')
          .doc(miNombre.toLowerCase())
          .set({
        'emoji': estado['emoji'],
        'nombre': estado['nombre'],
        'actualizado_por': miNombre,
        'fecha': DateTime.now().toIso8601String(),
      });

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error al actualizar estado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondoHogar,
      appBar: AppBar(
        title: const Text("¿Cómo estás, amor?"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
          ),
          itemCount: estados.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _actualizarEstado(context, estados[index]),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                      color: AppColores.azulTuyo.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(estados[index]['emoji']!,
                        style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      estados[index]['nombre']!,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColores.textoPrincipal),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
