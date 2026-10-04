import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../widgets/modal_unirse.dart'; // Importamos el modal para el botón "+ Unirse"

class PanelEstudiante extends StatefulWidget {
  const PanelEstudiante({Key? key}) : super(key: key);

  @override
  _PanelEstudianteState createState() => _PanelEstudianteState();
}

class _PanelEstudianteState extends State<PanelEstudiante> {
  List<dynamic> _aulas = [];
  bool _cargando = true;
  String? _errorMensaje;
  int? _estudianteId;

  @override
  void initState() {
    super.initState();
    _obtenerAulas();
  }

  Future<void> _obtenerAulas() async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _estudianteId = prefs.getInt('usuario_id');

      if (_estudianteId == null) {
        setState(() => _errorMensaje = 'Error de sesión. Vuelve a ingresar.');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/estudiantes/$_estudianteId/aulas/'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _aulas = jsonDecode(utf8.decode(response.bodyBytes));
        });
      } else {
        setState(() => _errorMensaje = 'No se pudieron cargar tus clases');
      }
    } catch (e) {
      setState(() => _errorMensaje = 'Error de conexión con el servidor');
    } finally {
      setState(() => _cargando = false);
    }
  }

  // --- SOLUCIÓN: FUNCIÓN BLINDADA CON DIÁLOGO DE CONFIRMACIÓN ---
  Future<void> _abandonarClase(int aulaId, String nombreAula) async {
    // 1. Mostrar advertencia
    bool confirmar =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Abandonar Clase',
              style: TextStyle(color: Color(0xFFEF233C)),
            ),
            content: Text(
              '¿Estás seguro de que deseas salir de la clase "$nombreAula"? Ya no podrás ver los pictogramas ni las rutinas asignadas por tu profesor.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Salir de la clase',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    // Si el usuario cancela, detenemos la función aquí
    if (!confirmar) return;

    // 2. Si confirma, procedemos a enviar el DELETE al servidor
    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/aulas/$aulaId/estudiantes/$_estudianteId',
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saliste de la clase con éxito'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _obtenerAulas(); // Recarga la lista para que desaparezca el aula abandonada
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al salir de la clase')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión con el servidor')),
      );
    }
  }

  void _abrirModalUnirse() async {
    final resultado = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ModalUnirseClase(),
    );

    // Si el modal devuelve true (es decir, el usuario se unió con éxito), recargamos la lista
    if (resultado == true) {
      _obtenerAulas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Mi Espacio',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2B2D42),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2B2D42),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Cabecera idéntica a tu captura de pantalla
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Clases',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2B2D42),
                  ),
                ),
                TextButton.icon(
                  onPressed: _abrirModalUnirse,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFFFFB703),
                  ),
                  label: const Text(
                    'Unirse',
                    style: TextStyle(
                      color: Color(0xFFFFB703),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4361EE)),
                  )
                : _errorMensaje != null
                ? Center(
                    child: Text(
                      _errorMensaje!,
                      style: const TextStyle(
                        color: Color(0xFFEF233C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : _aulas.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFF4361EE),
                    onRefresh: _obtenerAulas,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: _aulas.length,
                      itemBuilder: (context, index) {
                        final aula = _aulas[index];
                        return _buildAulaCard(aula);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.backpack_rounded,
            size: 80,
            color: const Color(0xFF4361EE).withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aún no estás inscrito en ninguna clase',
            style: TextStyle(color: Color(0xFF8D99AE), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAulaCard(Map<String, dynamic> aula) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4361EE).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF4361EE).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF4361EE),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aula['nombre'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF2B2D42),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Docente: ${aula['docente']}',
                    style: const TextStyle(
                      color: Color(0xFF8D99AE),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.exit_to_app_rounded,
                color: Color(0xFFEF233C),
                size: 28,
              ),
              tooltip: 'Abandonar Clase',
              onPressed: () => _abandonarClase(aula['id'], aula['nombre']),
            ),
          ],
        ),
      ),
    );
  }
}
