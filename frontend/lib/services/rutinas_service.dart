import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class RutinasService {
  static Future<List<dynamic>> obtenerRutinas(int estudianteId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/estudiantes/$estudianteId/rutinas/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 404) {
      // SOLUCIÓN: Si el backend dice 404 (No encontrado),
      // simplemente devolvemos una lista vacía en lugar de un error.
      return [];
    } else {
      throw Exception('Error al cargar rutinas');
    }
  }

  static Future<void> eliminarRutina(int rutinaId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/rutinas/$rutinaId'),
    );
    if (response.statusCode != 200) throw Exception('Error eliminando rutina');
  }

  static Future<void> crearRutina(
    int estudianteId,
    String titulo,
    List<Map<String, dynamic>> pasos,
    int? aulaId,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/estudiantes/$estudianteId/rutinas/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "titulo": titulo.trim(),
        "pasos": pasos,
        "aula_id": aulaId,
      }),
    );
    if (response.statusCode != 200) throw Exception('Error al crear la rutina');
  }
}
