import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colores.dart';
import '../services/notificacion_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _controller = TextEditingController();
  String _miNombre = "";
  List<dynamic> _frasesPredeterminadas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    // Cargar las 30 frases del JSON que tienes en assets
    final String response =
        await rootBundle.loadString('assets/data/frases.json');
    final data = await json.decode(response);

    setState(() {
      _miNombre = prefs.getString('rol_usuario') ?? "Usuario";
      _frasesPredeterminadas = data;
    });
  }

  Future<void> _enviarNota(String texto) async {
    if (texto.isEmpty) return;

    if (Platform.isLinux) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Simulación Linux: Enviando nota -> $texto")),
      );
      return;
    }

    // Guardado en Firebase
    await FirebaseFirestore.instance.collection('notas').add({
      'texto': texto,
      'autor': _miNombre,
      'fecha': FieldValue.serverTimestamp(),
    });

    // 2. DISPARAR NOTIFICACIÓN PUSH
    String destinatario = (_miNombre == "Isael") ? "mariana" : "isael";

    await NotificacionService.enviarNotificacion(
      aQuien: destinatario,
      titulo: 'Nueva nota de $_miNombre ✨',
      cuerpo: texto, // El cuerpo de la notificación será el texto de la nota
    );

    _controller.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✨ Nota enviada con éxito"),
          backgroundColor: AppColores.azulTuyo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondoHogar,
      appBar: AppBar(
        title: const Text("Notas de Apoyo",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColores.azulTuyo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. SECCIÓN: FRASES RÁPIDAS (JSON)
          const Padding(
            padding: EdgeInsets.only(top: 15, left: 15),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text("💡 Envío rápido",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey))),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: _frasesPredeterminadas.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () =>
                      _enviarNota(_frasesPredeterminadas[index]['texto']),
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColores.rojoElla.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: AppColores.rojoElla.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        _frasesPredeterminadas[index]['texto'],
                        style: const TextStyle(
                            fontSize: 11, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. SECCIÓN: ESCRIBIR NOTA
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Escribe algo tú mismo...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => _enviarNota(_controller.text),
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                      backgroundColor: AppColores.azulTuyo),
                ),
              ],
            ),
          ),

          const Divider(),

          // 3. SECCIÓN: MURO DE HISTORIAL (Firebase)
          Expanded(
            child: Platform.isLinux
                ? const Center(child: Text("Historial no disponible en Linux"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notas')
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final notas = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: notas.length,
                        itemBuilder: (context, index) {
                          var nota = notas[index];
                          bool esMio = nota['autor'] == _miNombre;

                          return Align(
                            alignment: esMio
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 5),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: esMio
                                      ? AppColores.azulTuyo
                                          .withValues(alpha: 0.8)
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(15),
                                    topRight: const Radius.circular(15),
                                    bottomLeft: Radius.circular(esMio ? 15 : 0),
                                    bottomRight:
                                        Radius.circular(esMio ? 0 : 15),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(2, 2))
                                  ]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nota['texto'],
                                    style: TextStyle(
                                        color: esMio
                                            ? Colors.white
                                            : AppColores.textoPrincipal),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    esMio ? "Tú" : nota['autor'],
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: esMio
                                            ? Colors.white70
                                            : Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
