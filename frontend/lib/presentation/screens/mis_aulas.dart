import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'crear_aula.dart';
import '../../services/api_service.dart';
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
    _obtenerAulas();
  }

  Future<void> _obtenerAulas() async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final docenteId = prefs.getInt('usuario_id');

      if (docenteId == null) {
        setState(() => _errorMensaje = 'Error de sesión. Vuelve a ingresar.');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/docente/$docenteId/aulas/'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _aulas = jsonDecode(utf8.decode(response.bodyBytes));
        });
      } else {
        setState(() => _errorMensaje = 'No se pudieron cargar las aulas');
      }
    } catch (e) {
      setState(() => _errorMensaje = 'Error de conexión con el servidor');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _expulsarAlumno(int aulaId, int estudianteId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/aulas/$aulaId/estudiantes/$estudianteId',
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estudiante removido'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _obtenerAulas();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al remover estudiante')),
      );
    }
  }

  Future<void> _eliminarAula(int aulaId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/aulas/$aulaId'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aula eliminada'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _obtenerAulas();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al eliminar aula')));
    }
  }

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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2B2D42),
          ),
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
          _obtenerAulas();
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
              onRefresh: _obtenerAulas,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: 80,
                ),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: _aulas.length,
                itemBuilder: (context, index) {
                  return _buildAulaCard(_aulas[index]);
                },
              ),
            ),
    );
  }

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
                  bool confirmar =
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar Clase'),
                          content: const Text(
                            '¿Estás seguro de que deseas eliminar esta clase y expulsar a todos sus estudiantes?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmar) _eliminarAula(aula['id']);
                },
              ),
            ],
          ),
          // CORRECCIÓN CLAVE: mainAxisSize: MainAxisSize.min
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado')),
                      );
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
                      mainAxisSize:
                          MainAxisSize.min, // Evita Height Overflow interno
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

  // NUEVO WIDGET: Para evitar desbordamientos de botones y mejorar el UI del estudiante
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
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
                icon: const Icon(
                  Icons.format_list_numbered_rounded,
                  color: Color(0xFFFFB703),
                  size: 22,
                ),
                tooltip: 'Rutinas',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RutinasScreen(
                        estudianteId: alumno['id'],
                        nombreEstudiante: alumno['nombre'],
                        isDocente: true,
                        aulaId:
                            aulaId, // <-- AQUÍ ESTÁ LA CORRECCIÓN, pasamos la variable directamente
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
                icon: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF4361EE),
                  size: 22,
                ),
                tooltip: 'Ver Progreso',
                onPressed: () {
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
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
                icon: const Icon(
                  Icons.person_remove_rounded,
                  color: Color(0xFFEF233C),
                  size: 22,
                ),
                tooltip: 'Expulsar',
                onPressed: () async {
                  bool confirmar =
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Expulsar Alumno'),
                          content: Text(
                            '¿Seguro que deseas remover a ${alumno['nombre']} de esta clase?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Expulsar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmar) _expulsarAlumno(aulaId, alumno['id']);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
