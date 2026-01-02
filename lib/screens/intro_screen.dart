import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../utils/colores.dart'; // Asegúrate de que la ruta sea correcta

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  // Lista de tus fotos en assets/images/
  // Asegúrate de que los nombres coincidan exactamente con tus archivos
  final List<String> fotos = [
    'assets/images/foto1.jpg',
    'assets/images/foto2.jpg',
    'assets/images/foto3.jpg',
    'assets/images/foto4.jpg',
    'assets/images/foto5.jpg',
    'assets/images/foto6.jpg',
    'assets/images/foto7.jpg',
    'assets/images/foto8.jpg',
    'assets/images/foto9.jpg',
    'assets/images/foto10.jpg',
    'assets/images/foto11.jpg',
    'assets/images/foto12.jpg',
    'assets/images/foto13.jpg',
    'assets/images/foto14.jpg',
    'assets/images/foto15.jpg',
    'assets/images/foto16.jpg',
    'assets/images/foto17.jpg',
    'assets/images/foto18.jpg',
    'assets/images/foto19.jpg',
    'assets/images/foto20.jpg',
    'assets/images/foto21.jpg',
    'assets/images/foto22.jpg',
    'assets/images/foto23.jpg',
    'assets/images/foto24.jpg',
    'assets/images/foto25.jpg',
    'assets/images/foto26.jpg',
    'assets/images/foto27.jpg',
    'assets/images/foto28.jpg',
    'assets/images/foto29.jpg',
    'assets/images/foto30.jpg',
    'assets/images/foto31.jpg',
    'assets/images/foto32.jpg',
    'assets/images/foto33.jpg',
    'assets/images/foto34.jpg',
    'assets/images/foto35.jpg',
    'assets/images/foto36.jpg',
    'assets/images/foto37.jpg',
    'assets/images/foto38.jpg',
    'assets/images/foto39.jpg',
    'assets/images/foto40.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Mezcla las fotos cada vez que se carga la pantalla
    fotos.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. COLLAGE DE FONDO
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 fotos por fila
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 0.8, // Controla la altura de las celdas
            ),
            itemCount: fotos.length,
            itemBuilder: (context, index) {
              return Image.asset(
                fotos[index],
                fit: BoxFit.cover,
                // Manejo de error por si alguna imagen no carga
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColores.azulTuyo.withValues(alpha: 0.1),
                    child: const Icon(Icons.favorite, color: Colors.white24),
                  );
                },
              );
            },
          ),

          // 2. CAPA DE OSCURECIMIENTO (Para que el texto resalte)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35), // Cambiado
            ),
          ),

          // 3. RECUADRO CENTRAL (La "Nota")
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              margin: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                color: AppColores.fondoHogar, // Crema Hueso
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color:
                        AppColores.acentoOro.withValues(alpha: 0.4), // Cambiado
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono decorativo arriba del texto
                  const Icon(Icons.favorite,
                      color: AppColores.rojoElla, size: 40),
                  const SizedBox(height: 20),

                  // El mensaje que pediste
                  const Text(
                    "Tu pareja te espera del otro lado",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColores.azulTuyo, // Tu azul
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    "Abre este diario para compartir tus pensamientos, recuerdos y sueños juntos. Cada entrada es un paso más en nuestro viaje como pareja.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColores.textoPrincipal,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Botón para ir al Home
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColores.rojoElla,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Entrar al diario",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
