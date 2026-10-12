import 'package:flutter/material.dart';
import '../../services/usuarios_service.dart';

class PanelAdminScreen extends StatefulWidget {
  const PanelAdminScreen({super.key});

  @override
  State<PanelAdminScreen> createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends State<PanelAdminScreen> {
  List<dynamic> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  // --- LÓGICA DE ESTADO LIMPIA ---
  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final usuarios = await UsuariosService.obtenerUsuarios();
      setState(() => _usuarios = usuarios);
    } catch (e) {
      _mostrarMensaje(e.toString().replaceAll("Exception: ", ""), error: true);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminarUsuario(int id, String nombre) async {
    bool confirmar = await _mostrarDialogoConfirmacion(
      'Eliminar Perfil',
      '¿Seguro que deseas eliminar definitivamente a $nombre y todos sus datos clínicos? Esta acción no se puede deshacer.',
      esDestructivo: true,
    );
    if (!confirmar) return;

    try {
      await UsuariosService.eliminarUsuario(id);
      _mostrarMensaje('Usuario $nombre eliminado con éxito');
      _cargarUsuarios();
    } catch (e) {
      _mostrarMensaje(e.toString().replaceAll("Exception: ", ""), error: true);
    }
  }

  Future<void> _restablecerClave(int id, String nombre) async {
    bool confirmar = await _mostrarDialogoConfirmacion(
      'Restablecer Contraseña',
      'La contraseña de $nombre será reiniciada a su número de DNI. ¿Deseas proceder?',
      esDestructivo: false,
    );
    if (!confirmar) return;

    try {
      await UsuariosService.restablecerClave(id);
      _mostrarMensaje('Contraseña de $nombre restablecida exitosamente');
    } catch (e) {
      _mostrarMensaje(e.toString().replaceAll("Exception: ", ""), error: true);
    }
  }

  // --- HELPERS DE UI REUTILIZABLES ---
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

  // --- CUADRO DE DIÁLOGO UNIFICADO (Como en Rutinas e Intereses) ---
  Future<bool> _mostrarDialogoConfirmacion(
    String titulo,
    String contenido, {
    bool esDestructivo = true,
  }) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  esDestructivo
                      ? Icons.warning_amber_rounded
                      : Icons.lock_reset_rounded,
                  color: esDestructivo
                      ? const Color(0xFFEF233C)
                      : const Color(0xFF4361EE),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              contenido,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: esDestructivo
                      ? const Color(0xFFEF233C).withValues(alpha: 0.1)
                      : const Color(0xFF4361EE).withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  esDestructivo ? 'Eliminar' : 'Confirmar',
                  style: TextStyle(
                    color: esDestructivo
                        ? const Color(0xFFEF233C)
                        : const Color(0xFF4361EE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Helper para asignar colores según el rol
  Color _getColorPorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return const Color(0xFF3A0CA3);
      case 'docente':
      case 'terapeuta':
        return const Color(0xFF4361EE);
      case 'familiar':
        return const Color(0xFFF72585);
      default:
        return const Color(0xFF10B981); // Estudiante
    }
  }

  // --- INTERFAZ GRÁFICA RENOVADA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fondo más limpio
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2B2D42),
        // Ícono consistente con el resto de la app
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4361EE)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final user = _usuarios[index];
                final colorRol = _getColorPorRol(user['rol']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: colorRol, // Acento de color según el rol
                            width: 5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Avatar tipográfico
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: colorRol.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user['rol'][0].toUpperCase(),
                              style: TextStyle(
                                color: colorRol,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),

                          // Información del usuario
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user['nombres']} ${user['apellidos']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF2B2D42),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user['email'],
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorRol.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user['rol'].toUpperCase(),
                                    style: TextStyle(
                                      color: colorRol,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Botones de acción
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.lock_reset_rounded,
                                  color: Color(0xFF4361EE),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Restablecer Clave',
                                onPressed: () => _restablecerClave(
                                  user['id'],
                                  user['nombres'],
                                ),
                              ),
                              const SizedBox(height: 10),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFEF233C),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Eliminar Usuario',
                                onPressed: () => _eliminarUsuario(
                                  user['id'],
                                  user['nombres'],
                                ),
                              ),
                            ],
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
