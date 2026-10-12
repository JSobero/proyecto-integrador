import 'package:flutter/material.dart';
import '../../services/estudiantes_service.dart';
import '../widgets/modal_unirse.dart';
import 'dashboard_analitico.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PanelEstudiante extends StatefulWidget {
  const PanelEstudiante({super.key});

  @override
  State<PanelEstudiante> createState() => _PanelEstudianteState();
}

class _PanelEstudianteState extends State<PanelEstudiante> {
  List<dynamic> _aulas = [];
  bool _cargando = true;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // --- LÓGICA DE ESTADO LIMPIA ---
  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final aulas = await EstudiantesService.obtenerAulasInscritas();
      setState(() => _aulas = aulas);
    } catch (e) {
      setState(
        () => _errorMensaje = e.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _abandonarClase(int aulaId, String nombreAula) async {
    bool confirmar = await _mostrarDialogoConfirmacion(
      'Abandonar Clase',
      '¿Estás seguro de que deseas salir de la clase "$nombreAula"? Ya no podrás ver los pictogramas ni las rutinas asignadas por tu profesor.',
    );
    if (!confirmar) return;

    try {
      await EstudiantesService.abandonarClase(aulaId);
      _mostrarMensaje('Saliste de la clase con éxito', error: false);
      _cargarDatos();
    } catch (e) {
      _mostrarMensaje(e.toString().replaceAll("Exception: ", ""), error: true);
    }
  }

  void _abrirModalUnirse() async {
    final resultado = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ModalUnirseClase(),
    );
    if (resultado == true) _cargarDatos();
  }

  // --- HELPERS DE UI REUTILIZABLES ---
  void _mostrarMensaje(String mensaje, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error
            ? const Color(0xFFEF233C)
            : const Color(0xFF10B981),
      ),
    );
  }

  // --- CUADRO DE DIÁLOGO UNIFICADO ESTÁNDAR ---
  Future<bool> _mostrarDialogoConfirmacion(
    String titulo,
    String contenido,
  ) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF233C),
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
                  backgroundColor: const Color(
                    0xFFEF233C,
                  ).withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Abandonar', // Ajustado para ser corto y claro
                  style: TextStyle(
                    color: Color(0xFFEF233C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // --- INTERFAZ GRÁFICA ---
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
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
                Row(
                  children: [
                    // NUEVO BOTÓN: Progreso del Estudiante
                    IconButton(
                      icon: const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFF4361EE),
                      ),
                      tooltip: 'Mi Progreso',
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final id = prefs.getInt('usuario_id') ?? 0;
                        final nombre =
                            prefs.getString('nombre') ??
                            prefs.getString('nombres') ??
                            'Mi Progreso';

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DashboardAnalitico(
                                estudianteId: id,
                                nombreEstudiante: nombre,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    // BOTÓN ORIGINAL: Unirse a Clase
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
                    onRefresh: _cargarDatos,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: _aulas.length,
                      itemBuilder: (context, index) =>
                          _buildAulaCard(_aulas[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS INTERNOS ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.backpack_rounded,
            size: 80,
            color: const Color(0xFF4361EE).withValues(alpha: 0.3),
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
            color: const Color(0xFF4361EE).withValues(alpha: 0.05),
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
                color: const Color(0xFF4361EE).withValues(alpha: 0.1),
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
