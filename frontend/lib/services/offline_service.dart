import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class OfflineService {
  // Descarga la imagen desde la URL de ARASAAC y la guarda en el disco duro del celular
  static Future<String?> guardarImagenLocal(String palabra, String url) async {
    try {
      // 1. Buscamos la carpeta segura de la aplicación en el celular
      final directorio = await getApplicationDocumentsDirectory();
      // 2. Creamos la ruta donde guardaremos la imagen (Ej: .../app_docs/perro.png)
      final rutaArchivo = '${directorio.path}/$palabra.png';
      final archivo = File(rutaArchivo);

      // 3. Si el archivo ya existe, no gastamos internet, devolvemos la ruta local
      if (await archivo.exists()) {
        return rutaArchivo;
      }

      // 4. Si no existe, la descargamos de internet
      final respuesta = await http.get(Uri.parse(url));

      if (respuesta.statusCode == 200) {
        // 5. Escribimos los bytes en el disco duro
        await archivo.writeAsBytes(respuesta.bodyBytes);
        return rutaArchivo; // Devolvemos la ruta local (Ej: /data/user/0/.../perro.png)
      }
    } catch (e) {
      print("Error guardando imagen offline: $e");
    }
    return null;
  }
}
