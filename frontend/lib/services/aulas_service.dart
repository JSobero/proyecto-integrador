// Archivo: lib/services/aulas_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart'; // <-- Importamos la configuración global

class AulasService {
  // 1. Obtener todas las aulas de un docente
  static Future<List<dynamic>> obtenerAulasDocente() async {
    final prefs = await SharedPreferences.getInstance();
    final docenteId = prefs.getInt('usuario_id');

    if (docenteId == null) throw Exception('Sesión no encontrada');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/docente/$docenteId/aulas/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('No se pudieron cargar las aulas');
    }
  }

  // 2. Expulsar a un estudiante de un aula
  static Future<bool> expulsarEstudiante(int aulaId, int estudianteId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/aulas/$aulaId/estudiantes/$estudianteId'),
    );
    return response.statusCode == 200;
  }

  // 3. Eliminar un aula por completo
  static Future<bool> eliminarAula(int aulaId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/aulas/$aulaId'),
    );
    return response.statusCode == 200;
  }

  // 4. Crear una nueva aula
  static Future<void> crearAula(String nombre, String descripcion) async {
    final prefs = await SharedPreferences.getInstance();
    final docenteId = prefs.getInt('usuario_id');
    if (docenteId == null) throw Exception('Sesión no encontrada');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/aulas/?docente_id=$docenteId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al crear la clase');
    }
  }
}
