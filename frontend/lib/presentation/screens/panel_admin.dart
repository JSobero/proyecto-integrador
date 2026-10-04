import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';

class PanelAdminScreen extends StatefulWidget {
  const PanelAdminScreen({Key? key}) : super(key: key);

  @override
  _PanelAdminScreenState createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends State<PanelAdminScreen> {
  List<dynamic> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/'),
      );
      if (response.statusCode == 200) {
        setState(() => _usuarios = jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _mostrarMensaje('Error cargando lista de usuarios', error: true);
      }
    } catch (e) {
      _mostrarMensaje('Fallo de conexión con el servidor', error: true);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminarUsuario(int id, String nombre) async {
    // 1. Validar confirmación
    bool confirmar =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Eliminar Perfil',
              style: TextStyle(color: Color(0xFFEF233C)),
            ),
            content: Text(
              '¿Seguro que deseas eliminar definitivamente a $nombre y todos sus datos clínicos? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Sí, Eliminar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF233C),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    // 2. Proceso de eliminación
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/$id'),
      );

      if (response.statusCode == 200) {
        _mostrarMensaje('Usuario $nombre eliminado con éxito');
        _cargarUsuarios();
      } else {
        final data = jsonDecode(response.body);
        _mostrarMensaje(
          data['detail'] ?? 'Error al eliminar usuario',
          error: true,
        );
      }
    } catch (e) {
      _mostrarMensaje('No se pudo conectar con el servidor', error: true);
    }
  }

  Future<void> _restablecerClave(int id, String nombre) async {
    // 1. Validar confirmación
    bool confirmar =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Restablecer Contraseña',
              style: TextStyle(color: Color(0xFF4361EE)),
            ),
            content: Text(
              'La contraseña de $nombre será reiniciada.\n\nEl usuario deberá ingresar usando su DNI como contraseña. ¿Deseas proceder?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Restablecer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4361EE),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    // 2. Proceso de Restablecimiento
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/$id/reset-password'),
      );

      if (response.statusCode == 200) {
        _mostrarMensaje('Contraseña restablecida al DNI exitosamente');
      } else {
        final data = jsonDecode(response.body);
        _mostrarMensaje(
          data['detail'] ?? 'Error al restablecer la contraseña',
          error: true,
        );
      }
    } catch (e) {
      _mostrarMensaje('No se pudo conectar con el servidor', error: true);
    }
  }

  void _mostrarMensaje(String mensaje, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: error
            ? const Color(0xFFEF233C)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2B2D42),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3A0CA3)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final user = _usuarios[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF3A0CA3),
                        radius: 25,
                        child: Text(
                          user['rol'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      title: Text(
                        '${user['nombres']} ${user['apellidos']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2B2D42),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            user['email'],
                            style: const TextStyle(color: Color(0xFF8D99AE)),
                          ),
                          Text(
                            'Rol: ${user['rol']}',
                            style: const TextStyle(
                              color: Color(0xFF3A0CA3),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // BOTONES DE ADMINISTRACIÓN RESTRINGIDOS PARA NO DESBORDAR LA PANTALLA
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFF4361EE),
                              size: 28,
                            ),
                            tooltip: 'Restablecer Clave',
                            onPressed: () =>
                                _restablecerClave(user['id'], user['nombres']),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever_rounded,
                              color: Color(0xFFEF233C),
                              size: 26,
                            ),
                            tooltip: 'Eliminar Usuario',
                            onPressed: () =>
                                _eliminarUsuario(user['id'], user['nombres']),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
