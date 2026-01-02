import 'package:flutter/material.dart';

class AppColores {
  static const Color fondoHogar = Color(0xFFFFF9F0);
  static const Color azulTuyo = Color(0xFF8EACCD);
  static const Color rojoElla = Color(0xFFFF8B8B);
  static const Color textoPrincipal = Color(0xFF4A4A4A);
  static const Color acentoOro = Color(0xFFD4AF37);

  static final LinearGradient gradientePareja = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      azulTuyo,
      rojoElla.withValues(alpha: 0.8) // Cambia withOpacity por withValues
    ],
  );
}
