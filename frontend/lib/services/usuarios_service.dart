import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // 4. Actualizar el perfil del usuario (Mi Perfil)
  static Future<Map<String, dynamic>> actualizarPerfil(
    int usuarioId, {
    String? nombres,
    String? apellidos,
    String? email,
    String? dni,
    String? passwordActual,
    String? nuevaPassword,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/usuarios/$usuarioId/perfil');

      final bodyData = <String, dynamic>{};

      if (nombres != null && nombres.trim().isNotEmpty) {
        bodyData['nombres'] = nombres.trim();
      }

      if (apellidos != null && apellidos.trim().isNotEmpty) {
        bodyData['apellidos'] = apellidos.trim();
      }

      if (email != null && email.trim().isNotEmpty) {
        bodyData['email'] = email.trim();
      }

      if (dni != null && dni.trim().isNotEmpty) {
        bodyData['dni'] = dni.trim();
      }

      if (passwordActual != null && passwordActual.isNotEmpty) {
        bodyData['password_actual'] = passwordActual;
      }

      if (nuevaPassword != null && nuevaPassword.isNotEmpty) {
        bodyData['nueva_password'] = nuevaPassword;
      }

      // Evitar enviar una solicitud vacía
      if (bodyData.isEmpty) {
        return {'success': false, 'error': 'No hay cambios para actualizar'};
      }

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Actualizar datos locales
        final prefs = await SharedPreferences.getInstance();

        if (nombres != null && nombres.trim().isNotEmpty) {
          await prefs.setString('nombres', nombres.trim());
        }

        if (apellidos != null && apellidos.trim().isNotEmpty) {
          await prefs.setString('apellidos', apellidos.trim());
        }

        if (email != null && email.trim().isNotEmpty) {
          await prefs.setString('email', email.trim());
        }

        if (dni != null && dni.trim().isNotEmpty) {
          await prefs.setString('dni', dni.trim());
        }

        return {'success': true, 'mensaje': 'Perfil actualizado correctamente'};
      } else {
        return {
          'success': false,
          'error': responseData is Map
              ? responseData['detail'] ?? 'Error al actualizar'
              : 'Error al actualizar el perfil',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
}
