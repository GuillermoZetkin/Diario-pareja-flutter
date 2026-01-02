import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; //

// Importaciones de tu proyecto
import 'screens/intro_screen.dart';
import 'screens/user_selection_screen.dart';
import 'utils/colores.dart';
import 'firebase_options.dart';

// 1. Instancia global para las notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 2. Definición del Canal de Alta Importancia (Vital para Android 13+)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'Notificaciones de Amor', // título
  description: 'Este canal se usa para los latidos y notas de apoyo.',
  importance: Importance.max,
  enableVibration: true,
  playSound: true,
);

// Manejador de mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Aquí el sistema operativo se encarga de mostrar la notificación si viene con el payload correcto
  debugPrint("Mensaje en segundo plano: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargamos preferencias desde el inicio para saber quién es el usuario
  final prefs = await SharedPreferences.getInstance();
  final String? miRol = prefs.getString('rol_usuario');

  // Inicializar Firebase si no es Linux
  if (!Platform.isLinux) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Configurar el manejador de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Configurar Notificaciones Locales
    await _configurarNotificacionesLocales();

    // 4. Pedir permisos para Android 13+ (S25 Ultra)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 5. Suscribirse al tema personal para recibir notificaciones
    if (miRol != null) {
      // Si miRol es "Isael", se suscribe al topic "isael"
      await FirebaseMessaging.instance.subscribeToTopic(miRol.toLowerCase());
      debugPrint("Suscrito al tema: ${miRol.toLowerCase()}");
    }
  }

  await initializeDateFormatting('es_ES', null);

  // Usamos el rol que ya cargamos arriba
  Widget pantallaInicial =
      miRol == null ? const UserSelectionScreen() : const IntroScreen();

  runApp(DiarioParejaApp(startWidget: pantallaInicial));
}

// Función de apoyo para configurar el canal de vibración
Future<void> _configurarNotificacionesLocales() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(
          '@mipmap/ic_launcher'); // Usa el icono de tu app

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Crear el canal en el sistema Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

class DiarioParejaApp extends StatelessWidget {
  final Widget startWidget;
  const DiarioParejaApp({super.key, required this.startWidget});

  @override
  Widget build(BuildContext context) {
    // Escuchar notificaciones mientras la app está ABIERTA (Foreground)
    if (!Platform.isLinux) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android.smallIcon,
                priority: Priority.high,
                importance: Importance.max,
                vibrationPattern: Int64List.fromList(
                    [0, 500, 200, 500]), // Patrón de vibración
              ),
            ),
          );
        }
      });
    }

    return MaterialApp(
      title: 'Diario de una pareja',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColores.fondoHogar,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColores.azulTuyo,
          primary: AppColores.azulTuyo,
          secondary: AppColores.rojoElla,
        ),
        textTheme: GoogleFonts.quicksandTextTheme(),
      ),
      home: startWidget,
    );
  }
}
