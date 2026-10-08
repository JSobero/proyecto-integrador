import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class MotorIAService {
  static Future<String?> obtenerImagenJit(String palabra) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pictogramas/generar/$palabra'),
      );
      if (res.statusCode == 200) return jsonDecode(res.body)['url'];
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<String> conjugarFrase(String fraseCruda) async {
    try {
      final fraseCodificada = Uri.encodeComponent(fraseCruda);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/frases/conjugar/$fraseCodificada'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))['msg'] ?? fraseCruda;
      }
    } catch (e) {
      return fraseCruda; // Fallback: si falla, devuelve la frase sin conjugar
    }
    return fraseCruda;
  }
}
