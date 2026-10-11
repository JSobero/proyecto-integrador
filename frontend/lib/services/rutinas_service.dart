import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class RutinasService {
  static Future<List<dynamic>> obtenerRutinas(int estudianteId) async {
    final prefs = await SharedPreferences.getInstance();
    final String cacheKey = 'rutinas_offline_$estudianteId';

    try {
      // 1. Intentamos buscar en el servidor (Con Internet)
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/estudiantes/$estudianteId/rutinas/',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          ); // Evita que se quede cargando infinito si la red es lenta

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // ¡MAGIA OFFLINE! Guardamos el JSON fresco en el disco local
        await prefs.setString(cacheKey, jsonEncode(data));

        return data;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Error al cargar rutinas');
      }
    } catch (e) {
      // 2. Si entra aquí, es porque NO HAY INTERNET (SocketException) o el servidor falló.
      // Leemos los datos que guardamos la última vez.
      final String? cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        // Devolvemos las rutinas guardadas localmente
        return jsonDecode(cachedData);
      } else {
        // Si no hay internet y es la primera vez que abre la app (nunca guardó nada)
        throw Exception(
          'No tienes conexión a internet para cargar las rutinas por primera vez.',
        );
      }
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
