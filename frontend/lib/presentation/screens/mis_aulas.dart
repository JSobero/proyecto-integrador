import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/aulas_service.dart';
import 'crear_aula.dart';
import 'dashboard_analitico.dart';
import 'rutinas_screen.dart';

class MisAulasScreen extends StatefulWidget {
  const MisAulasScreen({Key? key}) : super(key: key);

  @override
  _MisAulasScreenState createState() => _MisAulasScreenState();
}

class _MisAulasScreenState extends State<MisAulasScreen> {
  List<dynamic> _aulas = [];
  bool _cargando = true;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // --- LÓGICA DE ESTADO (Usando el Servicio Limpio) ---
  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final aulas = await AulasService.obtenerAulasDocente();
      setState(() => _aulas = aulas);
    } catch (e) {
      setState(
        () => _errorMensaje = e.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _expulsarAlumno(int aulaId, int estudianteId) async {
    try {
      final exito = await AulasService.expulsarEstudiante(aulaId, estudianteId);
      if (exito) {
        _mostrarMensaje('Estudiante removido', esError: false);
        _cargarDatos();
      }
    } catch (e) {
      _mostrarMensaje('Error al remover estudiante', esError: true);
    }
  }

  Future<void> _eliminarAula(int aulaId) async {
    try {
      final exito = await AulasService.eliminarAula(aulaId);
      if (exito) {
        _mostrarMensaje('Aula eliminada', esError: false);
        _cargarDatos();
      }
    } catch (e) {
      _mostrarMensaje('Error al eliminar aula', esError: true);
    }
  }

  void _mostrarMensaje(String texto, {required bool esError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor: esError
              ? const Color(0xFFEF233C)
              : const Color(0xFF10B981),
        ),
      );
    }
  }

  // --- INTERFAZ GRÁFICA (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Mis Aulas',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4361EE),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Crear Clase',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearAulaScreen()),
          );
          _cargarDatos();
        },
      ),
      body: _cargando
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: _aulas.length,
                itemBuilder: (context, index) => _buildAulaCard(_aulas[index]),
              ),
            ),
    );
  }

  // --- WIDGETS DE COMPONENTES INTERNOS ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_rounded,
            size: 80,
            color: const Color(0xFF4361EE).withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aún no tienes aulas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2D42),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Crea una clase para invitar a tus estudiantes.',
            style: TextStyle(color: Color(0xFF8D99AE)),
          ),
        ],
      ),
    );
  }

  Widget _buildAulaCard(Map<String, dynamic> aula) {
    final List<dynamic> alumnos = aula['alumnos'] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4361EE).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4361EE).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.class_rounded, color: Color(0xFF4361EE)),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  aula['nombre'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF2B2D42),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFEF233C),
                  size: 26,
                ),
                tooltip: 'Eliminar Clase',
                onPressed: () async {
                  bool confirmar = await _mostrarDialogoConfirmacion(
                    'Eliminar Clase',
                    '¿Deseas eliminar esta clase y expulsar a todos?',
                  );
                  if (confirmar) _eliminarAula(aula['id']);
                },
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              if (aula['descripcion'] != null &&
                  aula['descripcion'].toString().isNotEmpty)
                Text(
                  aula['descripcion'],
                  style: const TextStyle(color: Color(0xFF8D99AE)),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Código: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    aula['codigo_acceso'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: aula['codigo_acceso']),
                      );
                      _mostrarMensaje('Código copiado', esError: false);
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: Color(0xFF4361EE),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
              ),
              child: alumnos.isEmpty
                  ? const Center(
                      child: Text(
                        'Ningún estudiante se ha unido aún',
                        style: TextStyle(color: Color(0xFF8D99AE)),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Estudiantes Inscritos:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B2D42),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...alumnos.map(
                          (alumno) => _buildTarjetaAlumno(aula['id'], alumno),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaAlumno(int aulaId, dynamic alumno) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFF8E1),
            radius: 18,
            child: Icon(
              Icons.person_rounded,
              color: Color(0xFFFFB703),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alumno['nombre'],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2D42),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBotonAccion(
                Icons.format_list_numbered_rounded,
                const Color(0xFFFFB703),
                'Rutinas',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RutinasScreen(
                        estudianteId: alumno['id'],
                        nombreEstudiante: alumno['nombre'],
                        isDocente: true,
                        aulaId: aulaId,
                      ),
                    ),
                  );
                },
              ),
              _buildBotonAccion(
                Icons.bar_chart_rounded,
                const Color(0xFF4361EE),
                'Progreso',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardAnalitico(
                        estudianteId: alumno['id'],
                        nombreEstudiante: alumno['nombre'],
                      ),
                    ),
                  );
                },
              ),
              _buildBotonAccion(
                Icons.person_remove_rounded,
                const Color(0xFFEF233C),
                'Expulsar',
                () async {
                  bool confirmar = await _mostrarDialogoConfirmacion(
                    'Expulsar Alumno',
                    '¿Seguro que deseas remover a ${alumno['nombre']}?',
                  );
                  if (confirmar) _expulsarAlumno(aulaId, alumno['id']);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Refactor: Botones de iconos genéricos
  Widget _buildBotonAccion(
    IconData icono,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
      icon: Icon(icono, color: color, size: 22),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  // Refactor: Diálogo genérico
  Future<bool> _mostrarDialogoConfirmacion(
    String titulo,
    String contenido,
  ) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(titulo),
            content: Text(contenido),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
