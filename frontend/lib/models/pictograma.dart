// Ruta: lib/models/pictograma.dart

class Pictograma {
  final String palabra;
  final String? imagenUrl;

  Pictograma({required this.palabra, this.imagenUrl});

  // Backend -> App
  factory Pictograma.fromJson(Map<String, dynamic> json) {
    return Pictograma(
      palabra: json['palabra'] ?? '',
      imagenUrl: json['imagen_url'], // Soporta null safety si el backend falla
    );
  }

  // App -> Backend
  Map<String, dynamic> toJson() {
    return {'palabra': palabra, 'imagen_url': imagenUrl};
  }
}
