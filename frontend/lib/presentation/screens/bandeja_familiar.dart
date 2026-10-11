import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/estudiantes_service.dart';

class BandejaFamiliarScreen extends StatefulWidget {
  const BandejaFamiliarScreen({Key? key}) : super(key: key);

  @override
  _BandejaFamiliarScreenState createState() => _BandejaFamiliarScreenState();
}

class _BandejaFamiliarScreenState extends State<BandejaFamiliarScreen> {
  final TextEditingController _dniCtrl = TextEditingController();
  int? _hijoId;
  String? _nombreHijo;
  List<dynamic> _historial = [];
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _verificarVinculacion();
  }

  // --- LÓGICA DE ESTADO ---
  Future<void> _verificarVinculacion() async {
    final prefs = await SharedPreferences.getInstance();
    final guardadoId = prefs.getInt('hijo_vinculado_id');
    if (guardadoId != null) {
      setState(() {
        _hijoId = guardadoId;
        _nombreHijo = prefs.getString('hijo_vinculado_nombre') ?? "tu niño";
      });
      _cargarHistorial();
    }
  }

  Future<void> _vincularHijo() async {
    final dni = _dniCtrl.text.trim();
    if (dni.isEmpty || dni.length < 8) {
      setState(
        () => _errorMensaje = 'Ingresa un DNI válido (Mínimo 8 dígitos).',
      );
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final data = await EstudiantesService.vincularFamiliarPorDni(dni);
      setState(() {
        _hijoId = data['id'];
        _nombreHijo = data['nombre_completo'];
      });
      _cargarHistorial();
    } catch (e) {
      setState(
        () => _errorMensaje = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _desvincularHijo() async {
    bool confirmar = await _mostrarDialogoConfirmacion(
      'Desvincular Cuenta',
      '¿Estás seguro de que deseas dejar de monitorear a $_nombreHijo?',
      esDestructivo: true,
    );

    if (!confirmar) return;

    await EstudiantesService.desvincularFamiliar();
    setState(() {
      _hijoId = null;
      _nombreHijo = null;
      _historial = [];
      _dniCtrl.clear();
      _errorMensaje = null; // Limpia posibles errores anteriores
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta desvinculada exitosamente'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _cargarHistorial() async {
    if (_hijoId == null) return;
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final historial = await EstudiantesService.obtenerHistorialClinico(
        _hijoId!,
      );
      setState(() => _historial = historial);
    } catch (e) {
      setState(
        () => _errorMensaje = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  String _formatearFecha(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      // Formato más limpio, ej: "11 Oct - 03:51 PM"
      return DateFormat("dd MMM - hh:mm a", "es_ES").format(date);
    } catch (e) {
      return "Fecha desconocida";
    }
  }

  // --- CUADRO DE DIÁLOGO UNIFICADO ---
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
                      : Icons.info_outline_rounded,
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
                      ? const Color(0xFFEF233C).withOpacity(0.1)
                      : const Color(0xFF4361EE).withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  esDestructivo ? 'Desvincular' : 'Confirmar',
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

  // --- INTERFAZ GRÁFICA PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fondo más limpio
      appBar: AppBar(
        title: const Text(
          'Actividad Clínica', // Título más profesional
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2B2D42),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hijoId != null)
            IconButton(
              icon: const Icon(
                Icons.link_off_rounded,
                color: Color(0xFFEF233C),
              ),
              tooltip: 'Desvincular',
              onPressed: _desvincularHijo,
            ),
        ],
      ),
      body: _hijoId == null
          ? _buildPantallaVinculacion()
          : _buildPantallaHistorial(),
    );
  }

  // --- PANTALLA 1: VINCULACIÓN MEJORADA ---
  Widget _buildPantallaVinculacion() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono Hero
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF72585).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons
                    .admin_panel_settings_rounded, // Icono más adecuado para privacidad
                size: 70,
                color: Color(0xFFF72585),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Vinculación Segura',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2B2D42),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ingresa el número de DNI del estudiante. Esta medida protege la privacidad de los datos clínicos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 35),

            // Contenedor unificado para Input y Botón
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Manejo de Errores Limpio (No rompe el TextField)
                  if (_errorMensaje != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF233C).withOpacity(0.1),
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
                              _errorMensaje!,
                              style: const TextStyle(
                                color: Color(0xFFEF233C),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Campo DNI Limpio
                  TextField(
                    controller: _dniCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    decoration: InputDecoration(
                      hintText: 'Número de DNI',
                      counterText:
                          '', // Oculta el contador 0/12 para más limpieza
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.badge_rounded,
                        color: Color(0xFFF72585),
                      ),
                    ),
                    onSubmitted: (_) => _vincularHijo(),
                  ),
                  const SizedBox(height: 20),

                  // Botón
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _vincularHijo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF72585),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Vincular Cuenta',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PANTALLA 2: HISTORIAL CLÍNICO MEJORADO ---
  Widget _buildPantallaHistorial() {
    return Column(
      children: [
        // Tarjeta de Monitoreo Activo Superior
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoreo Activo',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vigilando a: $_nombreHijo',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF4361EE),
                ),
                onPressed: _cargarHistorial,
              ),
            ],
          ),
        ),

        // Lista de Historial
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
              : _historial.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 50,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Aún no hay actividad registrada hoy',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF4361EE),
                  onRefresh: _cargarHistorial,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: _historial.length,
                    itemBuilder: (context, index) {
                      final item = _historial[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFB703,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.touch_app_rounded,
                                color: Color(
                                  0xFFE99C00,
                                ), // Naranja un poco más oscuro para contraste
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: 'Comunicó: ',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: item['palabra'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2B2D42),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatearFecha(item['fecha_hora']),
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
