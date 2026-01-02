import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/colores.dart';
import 'mood_screen.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import '../services/notificacion_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- CONFIGURACIÓN DE FECHAS ---
  final DateTime fechaMeta = DateTime(2026, 12, 31, 23, 59);
  final DateTime fechaInicio = DateTime(2020, 7, 29);

  // --- TIMERS Y DURACIONES ---
  late Timer _timer;
  Duration _tiempoRestante = const Duration();

  // --- DATOS DE LA FRASE ---
  String _fraseActual = "Cargando tu mensaje...";
  String _autorActual = "";

  // --- VARIABLES DE ANIMACIÓN ---
  double _emojiScale = 1.0;
  double _heartScale = 1.0;
  bool _isHovering = false;

  // --- IDENTIDAD Y ESTADOS ---
  String _miNombre = "";
  String _nombrePareja = "";
  String _emojiPareja = "💖";
  String _estadoPareja = "Conectando...";
  String _distanciaTexto = "Buscando ubicación...";

  @override
  void initState() {
    super.initState();

    // Iniciamos la configuración de usuario y Firebase
    _inicializarApp();

    // Iniciamos el segundero para la cuenta regresiva
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (mounted) {
          _actualizarContador();
        }
      },
    );
  }

  @override
  void dispose() {
    // Limpiamos el timer al cerrar la pantalla
    _timer.cancel();
    super.dispose();
  }

  // --- LÓGICA DE INICIALIZACIÓN ---
  Future<void> _inicializarApp() async {
    _actualizarContador();
    _cargarFraseAleatoria();

    // Recuperamos quién es el usuario actual (Isael o Mariana)
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _miNombre = prefs.getString('rol_usuario') ?? "Usuario";
      _nombrePareja = (_miNombre == "Isael") ? "Mariana" : "Isael";
    });

    // Si estamos en un celular (Android), activamos Firebase
    if (!Platform.isLinux) {
      _gestionarUbicacion();
      _escucharFirebase();
    }
  }

  // --- ESCUCHADORES DE FIREBASE ---
  void _escucharFirebase() {
    // Escuchar si la pareja envía un latido
    FirebaseFirestore.instance
        .collection('interacciones')
        .doc('latido_compartido')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _ejecutarVibracion();
      }
    });

    // Escuchar el estado de ánimo (mood) de la pareja
    FirebaseFirestore.instance
        .collection('estados')
        .doc(_nombrePareja.toLowerCase())
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          _emojiPareja = snapshot.data()!['emoji'] ?? "💖";
          _estadoPareja = snapshot.data()!['nombre'] ?? "";
        });
      }
    });
  }

  // --- LÓGICA DE GEOLOCALIZACIÓN ---
  Future<void> _gestionarUbicacion() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Obtenemos mi posición
      Position position = await Geolocator.getCurrentPosition();

      // Subimos mi ubicación actual a la nube
      await FirebaseFirestore.instance
          .collection('ubicaciones')
          .doc(_miNombre.toLowerCase())
          .set({
        'lat': position.latitude,
        'lng': position.longitude,
        'ultima_vez': DateTime.now().toIso8601String(),
      });

      // Escuchamos la ubicación de mi pareja para calcular la distancia
      FirebaseFirestore.instance
          .collection('ubicaciones')
          .doc(_nombrePareja.toLowerCase())
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          double latP = snapshot.data()!['lat'];
          double lngP = snapshot.data()!['lng'];

          double metros = Geolocator.distanceBetween(
              position.latitude, position.longitude, latP, lngP);

          setState(() {
            _distanciaTexto =
                "A ${(metros / 1000).toStringAsFixed(1)} km de ti";
          });
        }
      });
    }
  }

  // --- LÓGICA DE UI Y EVENTOS ---
  void _actualizarContador() {
    setState(() {
      _tiempoRestante = fechaMeta.difference(DateTime.now());
    });
  }

  void _ejecutarVibracion() async {
    // Animación visual del emoji superior
    setState(() {
      _emojiScale = 1.4;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _emojiScale = 1.0;
        });
      }
    });

    // Vibración física del motor del celular
    if (!Platform.isLinux) {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [0, 200, 100, 400]);
      }
    }
  }

  Future<void> _enviarLatido() async {
    setState(() => _heartScale = 0.8);
    Future.delayed(const Duration(milliseconds: 100),
        () => setState(() => _heartScale = 1.0));

    if (Platform.isLinux) {
      _ejecutarVibracion();
      return;
    }

    await FirebaseFirestore.instance
        .collection('interacciones')
        .doc('latido_compartido')
        .set({
      'timestamp': DateTime.now().toIso8601String(),
      'enviado_por': _miNombre,
    });

    String destinatario = (_miNombre == "Isael") ? "mariana" : "isael";

    await NotificacionService.enviarNotificacion(
      aQuien: destinatario,
      titulo: '¡Latido de $_miNombre! ❤️',
      cuerpo: 'Está pensando en ti justo ahora.',
    );
  }

  Future<void> _cargarFraseAleatoria() async {
    try {
      final String respuesta =
          await rootBundle.loadString('assets/data/frases.json');
      final List<dynamic> datos = json.decode(respuesta);

      setState(() {
        int indice = Random().nextInt(datos.length);
        _fraseActual = datos[indice]['texto'];
        _autorActual = datos[indice]['autor'];
      });
    } catch (e) {
      debugPrint("Error al cargar JSON");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formateo de datos locales
    final String fechaHoy =
        DateFormat('dd MMMM, yyyy', 'es_ES').format(DateTime.now());
    final int diasJuntos = DateTime.now().difference(fechaInicio).inDays;

    return Scaffold(
      // 1. Agregamos el AppBar transparente para ver el icono del menú
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColores.azulTuyo, size: 30),
      ),

      // 2. Definimos el Menú Lateral (Drawer)
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColores.azulTuyo),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      "Hola, $_miNombre",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: AppColores.azulTuyo),
              title: const Text("Pantalla Principal"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: AppColores.rojoElla),
              title: const Text("Notas y Frases"),
              onTap: () {
                Navigator.pop(context); // Cierra el menú
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotesScreen()),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.calendar_month, color: AppColores.acentoOro),
              title: const Text("Calendario de Citas"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CalendarScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. BARRA SUPERIOR (Info Personal y Estado de Pareja)
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Información de relación y GPS
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Llevamos $diasJuntos días juntos",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColores.azulTuyo,
                                  fontSize: 17)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(_distanciaTexto,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),

                      // Estado de Ánimo de la Pareja
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MoodScreen()));
                        },
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: _emojiScale,
                              duration: const Duration(milliseconds: 200),
                              child: Text(_emojiPareja,
                                  style: const TextStyle(fontSize: 35)),
                            ),
                            Text(_estadoPareja,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColores.azulTuyo,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. TARJETA DE CUENTA REGRESIVA
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(vertical: 25),
                decoration: BoxDecoration(
                    gradient: AppColores.gradientePareja,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: AppColores.rojoElla.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ]),
                child: Column(
                  children: [
                    const Text("PARA VOLVER A ABRAZARNOS",
                        style: TextStyle(
                            color: Colors.white,
                            letterSpacing: 2,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTiempoItem(
                            _tiempoRestante.inDays.toString(), "DÍAS"),
                        _buildSeparador(),
                        _buildTiempoItem(
                            (_tiempoRestante.inHours % 24).toString(), "HRS"),
                        _buildSeparador(),
                        _buildTiempoItem(
                            (_tiempoRestante.inMinutes % 60).toString(), "MIN"),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 3. TARJETA DE LA FRASE DEL DÍA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                        color: AppColores.azulTuyo.withValues(alpha: 0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColores.acentoOro, size: 25),
                        const SizedBox(height: 15),
                        Text(
                          _fraseActual,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: AppColores.textoPrincipal),
                        ),
                        const SizedBox(height: 15),
                        Text("- $_autorActual",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColores.azulTuyo)),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 4. BOTÓN DEL CORAZÓN (LATIDO)
              MouseRegion(
                onEnter: (event) => setState(() => _isHovering = true),
                onExit: (event) => setState(() => _isHovering = false),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    _cargarFraseAleatoria();
                    _enviarLatido();
                  },
                  child: AnimatedScale(
                    scale: _isHovering ? 1.15 : _heartScale,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _isHovering
                                ? AppColores.rojoElla.withValues(alpha: 0.2)
                                : AppColores.rojoElla.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (_isHovering)
                                BoxShadow(
                                  color: AppColores.rojoElla
                                      .withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                )
                            ],
                          ),
                          child: const Icon(Icons.favorite,
                              color: AppColores.rojoElla, size: 45),
                        ),
                        const SizedBox(height: 10),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: AppColores.rojoElla,
                            fontWeight:
                                _isHovering ? FontWeight.w900 : FontWeight.bold,
                            fontSize: _isHovering ? 14 : 12,
                          ),
                          child: Text("Enviar latido a $_nombrePareja"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),

          // 5. FECHA (POSICIÓN FIJA INFERIOR DERECHA)
          Positioned(
            bottom: 20,
            right: 25,
            child: Text(
              fechaHoy,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO ---
  Widget _buildTiempoItem(String valor, String etiqueta) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(etiqueta,
            style: const TextStyle(
                fontSize: 9,
                color: Colors.white70,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSeparador() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text(":",
          style: TextStyle(
              color: Colors.white38,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
    );
  }
}
