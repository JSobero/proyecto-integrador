import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class UsuariosService {
  // 1. Obtener la lista de todos los usuarios
  static Future<List<dynamic>> obtenerUsuarios() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error cargando lista de usuarios');
    }
  }

  // 2. Eliminar un usuario
  static Future<void> eliminarUsuario(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/$id'),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al eliminar usuario');
    }
  }

  // 3. Restablecer la contraseña de un usuario
  static Future<void> restablecerClave(int id) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/$id/reset-password'),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al restablecer la contraseña');
    }
  }
}
