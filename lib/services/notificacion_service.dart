import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class NotificacionService {
  // El alcance necesario para enviar mensajes de Firebase
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  // Método privado para obtener el token de acceso usando tu archivo JSON
  static Future<String> _obtenerAccessToken() async {
    //  El archivo debe estar en assets/data/service-account.json
    final String response =
        await rootBundle.loadString('assets/data/service-account.json');
    final data = json.decode(response);

    final credentials = auth.ServiceAccountCredentials.fromJson(data);
    final client = await auth.clientViaServiceAccount(credentials, _scopes);

    return client.credentials.accessToken.data;
  }

  static Future<void> enviarNotificacion({
    required String aQuien, // "mariana" o "isael"
    required String titulo,
    required String cuerpo,
  }) async {
    try {
      final String accessToken = await _obtenerAccessToken();

      // Tu Project ID es 'diario-de-una-pareja'
      const String projectId = 'diario-de-una-pareja';
      const String url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'topic': aQuien,
            'notification': {
              'title': titulo,
              'body': cuerpo,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'high_importance_channel', //
                'notification_priority': 'PRIORITY_MAX',
                'sound': 'default',
              }
            }
          }
        }),
      );
    } catch (e) {
      // ignore: avoid_print
      print("Error al enviar notificación: $e");
    }
  }
}
