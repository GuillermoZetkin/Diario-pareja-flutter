import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colores.dart'; //
import '../services/notificacion_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _miNombre = "";

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _miNombre = prefs.getString('rol_usuario') ?? "Usuario";
    });
  }

  // Colores según el tipo de evento
  Color _getColorEvento(String tipo) {
    switch (tipo) {
      case 'Guardia':
        return Colors.teal;
      case 'Examen':
        return AppColores.acentoOro;
      case 'Cita':
        return AppColores.rojoElla;
      case 'Día Libre':
        return AppColores.azulTuyo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuestro Calendario"),
        backgroundColor: AppColores.azulTuyo, //
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'es_ES',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: AppColores.azulTuyo, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                  color: AppColores.rojoElla, shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColores.rojoElla,
        onPressed: () => _mostrarDialogoEvento(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Widget para listar eventos del día seleccionado
  Widget _buildEventList() {
    if (Platform.isLinux) {
      return const Center(
        child: Text(
            "Simulación: El calendario requiere Android para conectar con Firebase"),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection("calendario").snapshots(), //
      builder: (context, snapshot) {
        // 1. Error de conexión o permisos
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // 2. Cargando datos
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 3. Si no hay documentos o la colección está vacía
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No hay planes anotados ✨"));
        }

        // 4. Filtrado seguro de eventos
        final eventos = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Verificamos que el campo 'fecha' exista y sea del tipo correcto
          if (data["fecha"] == null || data["fecha"] is! Timestamp) {
            return false;
          }

          DateTime fechaDoc = (data["fecha"] as Timestamp).toDate();
          return isSameDay(fechaDoc, _selectedDay ?? _focusedDay); //
        }).toList();

        if (eventos.isEmpty) {
          return const Center(child: Text("No hay nada para este día"));
        }

        return ListView.builder(
          itemCount: eventos.length,
          itemBuilder: (context, index) {
            var ev = eventos[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: Icon(Icons.circle,
                  color: _getColorEvento(ev["tipo"] ?? "")), //
              title: Text(ev["titulo"] ?? "Sin título",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(ev["tipo"] ?? "General"),
              trailing: Text(ev["creado_por"] ?? "",
                  style: const TextStyle(fontSize: 10)),
            );
          },
        );
      },
    );
  }

  // Diálogo para agregar eventos (Guardias, Citas, etc.)
  void _mostrarDialogoEvento(BuildContext context) {
    String titulo = "";
    String tipo = "Guardia";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Evento"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                  hintText: "Título (Ej: Guardia Nocturna)"),
              onChanged: (val) => titulo = val,
            ),
            DropdownButtonFormField<String>(
              initialValue: tipo,
              items: ['Guardia', 'Hospital', 'Examen', 'Cita', 'Día Libre']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => tipo = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
              onPressed: () async {
                if (titulo.isEmpty) return;

                if (Platform.isLinux) {
                  // Simulación para Linux
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "Simulación: Evento '$titulo' guardado localmente")),
                  );
                  Navigator.pop(context);
                  return;
                }

                await FirebaseFirestore.instance.collection('calendario').add({
                  'titulo': titulo,
                  'tipo': tipo,
                  'fecha': Timestamp.fromDate(_selectedDay ?? _focusedDay),
                  'creado_por': _miNombre,
                });

                // Notificar a la pareja del nuevo evento
                String destinatario =
                    (_miNombre == "Isael") ? "mariana" : "isael";
                await NotificacionService.enviarNotificacion(
                  aQuien: destinatario,
                  titulo: "¡Nuevo plan en el calendario! 📅",
                  cuerpo: "$_miNombre agregó: $titulo ($tipo)",
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Guardar")),
        ],
      ),
    );
  }
}
