import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ModalUnirseClase extends StatefulWidget {
  const ModalUnirseClase({Key? key}) : super(key: key);

  @override
  _ModalUnirseClaseState createState() => _ModalUnirseClaseState();
}

class _ModalUnirseClaseState extends State<ModalUnirseClase> {
  final _codigoCtrl = TextEditingController();
  bool _cargando = false;
  String? _errorMensaje;

  Future<void> _unirseClase() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty || codigo.length != 6) {
      setState(
        () => _errorMensaje = 'El código debe tener exactamente 6 caracteres',
      );
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final estudianteId = prefs.getInt('usuario_id');

      if (estudianteId == null) {
        setState(() => _errorMensaje = 'No hay una sesión activa.');
        return;
      }

      // LA BARRA FINAL AHORA COINCIDE CON EL BACKEND
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/aulas/unirse/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"estudiante_id": estudianteId, "codigo": codigo}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Devuelve 'true' al cerrarse para avisar que hubo éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Te uniste a la clase con éxito!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        setState(
          () => _errorMensaje =
              data['detail'] ?? 'Código incorrecto o aula no encontrada',
        );
      }
    } catch (e) {
      setState(() => _errorMensaje = 'Error de conexión con el servidor');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 30,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unirse a una Clase',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2D42),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ingresa el código alfanumérico de 6 dígitos que te entregó el docente.',
              style: TextStyle(color: Color(0xFF8D99AE)),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _codigoCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Ej: ABC123',
                errorText: _errorMensaje,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFF4361EE),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _cargando ? null : _unirseClase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4361EE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'UNIRSE AHORA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
