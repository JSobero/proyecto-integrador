import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert'; // IMPORTANTE
import 'package:shared_preferences/shared_preferences.dart'; // IMPORTANTE
import '../../services/rutinas_service.dart';
import '../../services/motor_ia_service.dart';

class RutinasScreen extends StatefulWidget {
  final int estudianteId;
  final String nombreEstudiante;
  final bool isDocente;
  final int? aulaId;

  const RutinasScreen({
    super.key,
    required this.estudianteId,
    required this.nombreEstudiante,
    required this.isDocente,
    this.aulaId,
  });

  @override
  State<RutinasScreen> createState() => _RutinasScreenState();
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

  Future<void> _hablarRutinaCompleta(List pasos) async {
    if (pasos.isEmpty) return;

    String fraseCruda = pasos
        .map((p) => p['palabra'].toString().toLowerCase())
        .join(" ");

    try {
      String fraseFinal = await MotorIAService.conjugarFrase(fraseCruda);
      await flutterTts.speak(fraseFinal);
    } catch (e) {
      await flutterTts.speak(fraseCruda);
    }
  }

  Future<void> _cargarRutinas() async {
    setState(() => _cargando = true);
    try {
      final rutinas = await RutinasService.obtenerRutinas(widget.estudianteId);
      bool requiereActualizarCache = false;

      for (var rutina in rutinas) {
        for (var paso in rutina['pasos']) {
          if (paso['url'] == null || paso['url'].isEmpty) {
            try {
              paso['url'] = await MotorIAService.obtenerImagenJit(
                paso['palabra'],
              );
              requiereActualizarCache = true;
            } catch (e) {
              // Falla silenciosa permitida
            }
          }
        }
      }

      if (requiereActualizarCache) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'rutinas_offline_${widget.estudianteId}',
          jsonEncode(rutinas),
        );
      }

      setState(() => _rutinas = rutinas);
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(
          e.toString().replaceAll("Exception: ", ""),
          esError: true,
        );
      }
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
                  'Eliminar',
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

  // --- MODAL UNIFICADO PARA CREAR Y EDITAR ---
  void _abrirModalFormularioRutina({Map<String, dynamic>? rutinaAEditar}) {
    final bool esEdicion = rutinaAEditar != null;

    // Autocompleta el título si es edición, sino lo deja vacío
    final tituloCtrl = TextEditingController(
      text: esEdicion ? rutinaAEditar['titulo'] : '',
    );

    // Autocompleta los pasos si es edición, sino pone 2 cajas vacías por defecto
    List<TextEditingController> pasosCtrls = [];
    if (esEdicion) {
      final pasos = rutinaAEditar['pasos'] as List;
      for (var paso in pasos) {
        pasosCtrls.add(TextEditingController(text: paso['palabra']));
      }
    } else {
      pasosCtrls = [TextEditingController(), TextEditingController()];
    }

    String? errorModal;

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
                    esEdicion
                        ? 'Editar Rutina'
                        : (widget.isDocente
                              ? 'Rutina para la Clase'
                              : 'Mi Rutina Personal'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (errorModal != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF233C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFEF233C),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorModal!,
                              style: const TextStyle(
                                color: Color(0xFFEF233C),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

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
                    onChanged: (_) => setModalState(() => errorModal = null),
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
                                  onChanged: (_) =>
                                      setModalState(() => errorModal = null),
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
                                  onPressed: () => setModalState(() {
                                    pasosCtrls.removeAt(index);
                                    errorModal = null;
                                  }),
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
                          onPressed: () => setModalState(() {
                            pasosCtrls.add(TextEditingController());
                            errorModal = null;
                          }),
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
                              setModalState(
                                () => errorModal =
                                    'El título de la rutina es obligatorio.',
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
                              setModalState(
                                () => errorModal =
                                    'Debes escribir al menos una acción.',
                              );
                              return;
                            }

                            // --- FLUJO AL BACKEND ---
                            try {
                              if (esEdicion) {
                                await RutinasService.actualizarRutina(
                                  rutinaAEditar['id'],
                                  tituloCtrl.text,
                                  pasosLimpio,
                                );
                              } else {
                                await RutinasService.crearRutina(
                                  widget.estudianteId,
                                  tituloCtrl.text,
                                  pasosLimpio,
                                  widget.aulaId,
                                );
                              }

                              if (context.mounted) Navigator.pop(context);
                              _cargarRutinas();
                            } catch (e) {
                              // ERROR DEL SERVIDOR DENTRO DEL MODAL
                              setModalState(
                                () => errorModal = e.toString().replaceAll(
                                  "Exception: ",
                                  "",
                                ),
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
                          child: Text(
                            esEdicion ? 'Guardar Cambios' : 'Guardar',
                            style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(
          widget.isDocente
              ? 'Rutinas: ${widget.nombreEstudiante}'
              : 'Mis Rutinas',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
        // Al no enviar parámetros, se asume que es modo Creación
        onPressed: () => _abrirModalFormularioRutina(),
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

                final bool puedeEditarYBorrar =
                    (!widget.isDocente && esPersonal) ||
                    (widget.isDocente && !esPersonal);

                return Container(
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ENCABEZADO
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: esPersonal
                                          ? const Color(
                                              0xFFF72585,
                                            ).withValues(alpha: 0.1)
                                          : const Color(
                                              0xFF4361EE,
                                            ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      rutina['origen'],
                                      style: TextStyle(
                                        fontSize: 11,
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
                            // BOTÓN: REPRODUCIR TODA LA RUTINA
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF4361EE,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.volume_up_rounded,
                                  color: Color(0xFF4361EE),
                                ),
                                onPressed: () => _hablarRutinaCompleta(pasos),
                                tooltip: 'Escuchar rutina',
                              ),
                            ),

                            // BOTONES DE EDICIÓN Y ELIMINACIÓN (Protegidos por permisos)
                            if (puedeEditarYBorrar) ...[
                              const SizedBox(width: 8),
                              // BOTÓN: EDITAR RUTINA
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFB703,
                                  ).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    color: Color(
                                      0xFFE99C00,
                                    ), // Naranja quemado/Ambar
                                    size: 20,
                                  ),
                                  onPressed: () => _abrirModalFormularioRutina(
                                    rutinaAEditar: rutina,
                                  ),
                                  tooltip: 'Editar',
                                ),
                              ),
                              const SizedBox(width: 8),
                              // BOTÓN: ELIMINAR RUTINA
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEF233C,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFEF233C),
                                    size: 22,
                                  ),
                                  onPressed: () =>
                                      _eliminarRutina(rutina['id']),
                                  tooltip: 'Eliminar',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Divider(
                        color: Color(0xFFF4F7FC),
                        thickness: 2,
                        height: 1,
                      ),

                      // ZONA DE PICTOGRAMAS
                      Container(
                        height: 145,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(25),
                          ),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: pasos.length,
                          separatorBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFFCBD5E1),
                              size: 18,
                            ),
                          ),
                          itemBuilder: (ctx, stepIdx) {
                            final paso = pasos[stepIdx];
                            return InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () => flutterTts.speak(paso['palabra']),
                              child: SizedBox(
                                width: 85,
                                child: Column(
                                  children: [
                                    Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.02,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child:
                                            (paso['url'] != null &&
                                                paso['url']
                                                    .toString()
                                                    .isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl: paso['url'],
                                                fit: BoxFit.contain,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => const Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                      ),
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
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF2B2D42),
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
