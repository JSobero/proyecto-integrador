import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/rutinas_service.dart';
import '../../services/motor_ia_service.dart';

class RutinasScreen extends StatefulWidget {
  final int estudianteId;
  final String nombreEstudiante;
  final bool isDocente;
  final int? aulaId;

  const RutinasScreen({
    Key? key,
    required this.estudianteId,
    required this.nombreEstudiante,
    required this.isDocente,
    this.aulaId,
  }) : super(key: key);

  @override
  _RutinasScreenState createState() => _RutinasScreenState();
}

class _RutinasScreenState extends State<RutinasScreen> {
  bool _cargando = true;
  List<dynamic> _rutinas = [];
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _cargarRutinas();
    _configurarTTS();
  }

  Future<void> _configurarTTS() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.5);
  }

  // --- LÓGICA DE ESTADO LIMPIA ---
  Future<void> _cargarRutinas() async {
    setState(() => _cargando = true);
    try {
      final rutinas = await RutinasService.obtenerRutinas(widget.estudianteId);
      setState(() => _rutinas = rutinas);
    } catch (e) {
      if (mounted)
        _mostrarMensaje(
          e.toString().replaceAll("Exception: ", ""),
          esError: true,
        );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminarRutina(int rutinaId) async {
    bool confirmar = await _mostrarDialogoConfirmacion(
      'Eliminar Rutina',
      '¿Estás seguro de eliminar esta secuencia visual?',
    );
    if (!confirmar) return;

    try {
      await RutinasService.eliminarRutina(rutinaId);
      _mostrarMensaje('Rutina eliminada', esError: false);
      _cargarRutinas();
    } catch (e) {
      _mostrarMensaje(
        e.toString().replaceAll("Exception: ", ""),
        esError: true,
      );
    }
  }

  // --- HELPERS DE UI REUTILIZABLES ---
  void _mostrarMensaje(String mensaje, {required bool esError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError
            ? const Color(0xFFEF233C)
            : const Color(0xFF10B981),
      ),
    );
  }

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
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // --- MODAL DE CREACIÓN AISLADO ---
  void _abrirModalCrearRutina() {
    final tituloCtrl = TextEditingController();
    List<TextEditingController> pasosCtrls = [
      TextEditingController(),
      TextEditingController(),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                30,
                24,
                MediaQuery.of(context).viewInsets.bottom,
              ),
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isDocente
                        ? 'Rutina para la Clase'
                        : 'Mi Rutina Personal',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Título de la Rutina',
                    style: TextStyle(
                      color: Color(0xFF8D99AE),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: tituloCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ej: Lavarse las manos',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pasos cronológicos',
                    style: TextStyle(
                      color: Color(0xFF8D99AE),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pasosCtrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF4361EE),
                                radius: 15,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: pasosCtrls[index],
                                  decoration: InputDecoration(
                                    hintText: 'Acción (Ej: jabón)',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              if (pasosCtrls.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Color(0xFFEF233C),
                                  ),
                                  onPressed: () => setModalState(
                                    () => pasosCtrls.removeAt(index),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setModalState(
                            () => pasosCtrls.add(TextEditingController()),
                          ),
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Color(0xFF4361EE),
                          ),
                          label: const Text(
                            'Añadir Paso',
                            style: TextStyle(color: Color(0xFF4361EE)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: Color(0xFF4361EE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (tituloCtrl.text.trim().isEmpty) {
                              _mostrarMensaje(
                                'El título es obligatorio',
                                esError: true,
                              );
                              return;
                            }

                            List<Map<String, dynamic>> pasosLimpio = [];
                            for (int i = 0; i < pasosCtrls.length; i++) {
                              if (pasosCtrls[i].text.trim().isNotEmpty) {
                                pasosLimpio.add({
                                  "orden": i + 1,
                                  "palabra": pasosCtrls[i].text.trim(),
                                });
                              }
                            }
                            if (pasosLimpio.isEmpty) {
                              _mostrarMensaje(
                                'Debes agregar al menos un paso',
                                esError: true,
                              );
                              return;
                            }

                            try {
                              await RutinasService.crearRutina(
                                widget.estudianteId,
                                tituloCtrl.text,
                                pasosLimpio,
                                widget.aulaId,
                              );
                              if (mounted) Navigator.pop(context);
                              _cargarRutinas();
                            } catch (e) {
                              _mostrarMensaje(
                                e.toString().replaceAll("Exception: ", ""),
                                esError: true,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Guardar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- INTERFAZ GRÁFICA PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(
          widget.isDocente
              ? 'Rutinas de ${widget.nombreEstudiante}'
              : 'Mis Rutinas',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2B2D42),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalCrearRutina,
        backgroundColor: widget.isDocente
            ? const Color(0xFF4361EE)
            : const Color(0xFFF72585),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: Text(
          widget.isDocente ? 'Crear Rutina' : 'Mi Rutina Propia',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4361EE)),
            )
          : _rutinas.isEmpty
          ? Center(
              child: Text(
                'No hay rutinas programadas',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _rutinas.length,
              itemBuilder: (context, index) {
                final rutina = _rutinas[index];
                final List pasos = rutina['pasos'];
                final bool esPersonal = rutina['origen'] == "Personal";

                return Container(
                  margin: const EdgeInsets.only(bottom: 25),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rutina['titulo'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2B2D42),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: esPersonal
                                        ? const Color(
                                            0xFFF72585,
                                          ).withOpacity(0.1)
                                        : const Color(
                                            0xFF4361EE,
                                          ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    rutina['origen'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: esPersonal
                                          ? const Color(0xFFF72585)
                                          : const Color(0xFF4361EE),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isDocente || esPersonal)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFEF233C),
                              ),
                              onPressed: () => _eliminarRutina(rutina['id']),
                            ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: pasos.length,
                          itemBuilder: (ctx, stepIdx) {
                            final paso = pasos[stepIdx];
                            return InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () => flutterTts.speak(paso['palabra']),
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 15),
                                child: Column(
                                  children: [
                                    FutureBuilder<String?>(
                                      future: MotorIAService.obtenerImagenJit(
                                        paso['palabra'],
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting)
                                          return Container(
                                            height: 80,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        if (!snapshot.hasData ||
                                            snapshot.data == null)
                                          return Container(
                                            height: 80,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                            ),
                                          );
                                        return Container(
                                          height: 80,
                                          width: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                snapshot.data!,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 8,
                                          backgroundColor: const Color(
                                            0xFFFFB703,
                                          ),
                                          child: Text(
                                            '${paso['orden']}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            paso['palabra']
                                                .toString()
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
