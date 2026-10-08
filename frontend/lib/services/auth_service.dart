import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService {
  // 1. Lógica centralizada para Iniciar Sesión
  static Future<Map<String, dynamic>> iniciarSesion(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('usuario_id', data['id']);
      await prefs.setString('rol', data['rol']);
      return data;
    } else {
      final error = jsonDecode(response.body)['detail'];
      throw Exception(error);
    }
  }

  // 2. Lógica centralizada para Registrar Usuario
  static Future<void> registrarUsuario(Map<String, String> userData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 422) {
      final errorList = jsonDecode(response.body)['detail'];
      throw Exception('Error en los datos: ${errorList[0]['msg']}');
    } else {
      final error = jsonDecode(response.body)['detail'];
      throw Exception(error);
    }
  }
}