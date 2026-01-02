class Frase {
  final String texto;
  final String autor;

  Frase({required this.texto, required this.autor});

  // Esto permite convertir el JSON en un objeto de Dart
  factory Frase.fromJson(Map<String, dynamic> json) {
    return Frase(
      texto: json['texto'],
      autor: json['autor'],
    );
  }
}
