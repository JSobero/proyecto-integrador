// Ruta: lib/models/pictograma.dart
class Pictograma {
  final String palabra;
  final String? imagenUrl;

  Pictograma({required this.palabra, this.imagenUrl});

  factory Pictograma.fromJson(Map<String, dynamic> json) {
    return Pictograma(
      palabra: json['palabra'],
      imagenUrl: json['imagen_url'],
    );
  }
}