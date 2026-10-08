import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class EstudiantesService {
  // --- MÉTODOS EXISTENTES (Aulas) ---
  static Future<List<dynamic>> obtenerAulasInscritas() async {
    final prefs = await SharedPreferences.getInstance();
    final estudianteId = prefs.getInt('usuario_id');
    if (estudianteId == null) throw Exception('Error de sesión.');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/estudiantes/$estudianteId/aulas/'),
    );
    if (response.statusCode == 200)
      return jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception('No se pudieron cargar tus clases');
  }

  static Future<void> abandonarClase(int aulaId) async {
    final prefs = await SharedPreferences.getInstance();
    final estudianteId = prefs.getInt('usuario_id');
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/aulas/$aulaId/estudiantes/$estudianteId'),
    );
    if (response.statusCode != 200)
      throw Exception('Error al salir de la clase');
  }

  // --- NUEVOS MÉTODOS: VINCULACIÓN FAMILIAR ---
  static Future<Map<String, dynamic>> vincularFamiliarPorDni(String dni) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/estudiantes/vincular/$dni'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hijo_vinculado_id', data['id']);
      await prefs.setString('hijo_vinculado_nombre', data['nombre_completo']);
      return data;
    } else {
      throw Exception('No se encontró ningún estudiante con este DNI.');
    }
  }

  static Future<List<dynamic>> obtenerHistorialClinico(int estudianteId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/estudiantes/$estudianteId/historial/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('No se encontraron datos de actividad.');
    }
  }

  static Future<void> desvincularFamiliar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hijo_vinculado_id');
    await prefs.remove('hijo_vinculado_nombre');
  }

  // --- NUEVOS MÉTODOS: GESTIÓN DE INTERESES (Fringe Words) ---
  static Future<List<dynamic>> obtenerIntereses() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');
    if (usuarioId == null) throw Exception('Error de sesión.');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/estudiantes/$usuarioId/intereses/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error cargando intereses');
    }
  }

  static Future<void> agregarInteres(String palabraClave) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/estudiantes/$usuarioId/intereses/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'palabra_clave': palabraClave}),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['detail'];
      throw Exception(error);
    }
  }

  static Future<void> eliminarInteres(int interesId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/intereses/$interesId'),
    );
    if (response.statusCode != 200)
      throw Exception('Error al eliminar el interés');
  }

  // --- NUEVOS MÉTODOS: CONFIGURACIÓN CLÍNICA Y ACCESIBILIDAD ---
  static Future<Map<String, dynamic>> obtenerConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    // Configuración por defecto si el usuario es un invitado o falla la red
    Map<String, dynamic> configPorDefecto = {
      'densidad_visual': 8,
      'ocultar_texto': false,
      'vibracion_haptica': true,
      'tamano_fuente': 9.5,
    };

    if (usuarioId == null) return configPorDefecto;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/estudiantes/$usuarioId/configuracion/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardamos las configuraciones clave en SharedPreferences para acceso offline e inmediato por los botones
        await prefs.setBool(
          'cfg_ocultar_texto',
          data['ocultar_texto'] ?? false,
        );
        await prefs.setBool('cfg_haptica', data['vibracion_haptica'] ?? true);
        await prefs.setDouble(
          'cfg_fuente',
          (data['tamano_fuente'] ?? 9.5).toDouble(),
        );

        return data;
      }
    } catch (e) {
      // Si hay error (ej. sin internet), intentamos leer de la caché
    }

    // Respaldo desde caché
    configPorDefecto['ocultar_texto'] =
        prefs.getBool('cfg_ocultar_texto') ?? false;
    configPorDefecto['vibracion_haptica'] =
        prefs.getBool('cfg_haptica') ?? true;
    configPorDefecto['tamano_fuente'] = prefs.getDouble('cfg_fuente') ?? 9.5;

    return configPorDefecto;
  }

  static Future<void> guardarConfiguracion(
    Map<String, dynamic> configuracion,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    // Guardamos localmente para latencia cero en la UI
    await prefs.setBool(
      'cfg_ocultar_texto',
      configuracion['ocultar_texto'] ?? false,
    );
    await prefs.setBool(
      'cfg_haptica',
      configuracion['vibracion_haptica'] ?? true,
    );
    await prefs.setDouble(
      'cfg_fuente',
      (configuracion['tamano_fuente'] ?? 9.5).toDouble(),
    );

    if (usuarioId == null) return; // Si es invitado, solo guarda en caché

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/estudiantes/$usuarioId/configuracion/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(configuracion),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al sincronizar configuración con el servidor');
    }
  }

  static Future<Map<String, dynamic>> obtenerEstadisticas(
    int estudianteId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/estudiantes/$estudianteId/estadisticas/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error cargando métricas');
    }
  }

  // Añade este nuevo método
  static Future<void> registrarTrackingClinico(String palabra) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');
    if (usuarioId == null) return;
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/estudiantes/$usuarioId/tracking/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'palabra': palabra}),
      );
    } catch (
      _
    ) {} // Silencioso: si falla el tracking, no debe interrumpir la app
  }
}
