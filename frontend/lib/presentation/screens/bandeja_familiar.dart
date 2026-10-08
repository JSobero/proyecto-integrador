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

  // --- LÓGICA DE ESTADO LIMPIA ---
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
        () => _errorMensaje = 'Ingresa un DNI válido (Mínimo 8 dígitos)',
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
    bool confirmar =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Desvincular Cuenta',
              style: TextStyle(color: Color(0xFFEF233C)),
            ),
            content: Text(
              '¿Estás seguro de que deseas dejar de monitorear a $_nombreHijo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Desvincular',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    await EstudiantesService.desvincularFamiliar();
    setState(() {
      _hijoId = null;
      _nombreHijo = null;
      _historial = [];
      _dniCtrl.clear();
    });
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta desvinculada exitosamente')),
      );
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
      return DateFormat("dd MMM yyyy - hh:mm a", "es_ES").format(date);
    } catch (e) {
      return "Fecha desconocida";
    }
  }

  // --- INTERFAZ GRÁFICA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Actividad de mi Niño',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2B2D42),
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

  Widget _buildPantallaVinculacion() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF72585).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security_rounded,
                size: 80,
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
            const SizedBox(height: 15),
            const Text(
              'Ingresa el número de DNI de tu hijo. Esta medida asegura que solo los familiares directos puedan ver su actividad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8D99AE), fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _dniCtrl,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: InputDecoration(
                hintText: 'DNI del estudiante',
                errorText: _errorMensaje,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.badge_rounded,
                  color: Color(0xFFF72585),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _cargando ? null : _vincularHijo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF72585),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'VINCULAR CUENTA',
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
    );
  }

  Widget _buildPantallaHistorial() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.monitor_heart_rounded,
                color: Color(0xFF10B981),
                size: 30,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoreo Activo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    Text(
                      'Vigilando a: $_nombreHijo',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8D99AE),
                        fontWeight: FontWeight.w600,
                      ),
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
        Expanded(
          child: _cargando
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF72585)),
                )
              : _errorMensaje != null
              ? Center(
                  child: Text(
                    _errorMensaje!,
                    style: const TextStyle(color: Color(0xFFEF233C)),
                  ),
                )
              : _historial.isEmpty
              ? const Center(
                  child: Text(
                    'Aún no hay interacciones registradas hoy',
                    style: TextStyle(color: Color(0xFF8D99AE)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _historial.length,
                  itemBuilder: (context, index) {
                    final item = _historial[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.touch_app_rounded,
                              color: Color(0xFFFFB703),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Comentó: ${item['palabra']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Color(0xFF2B2D42),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _formatearFecha(item['fecha_hora']),
                                  style: const TextStyle(
                                    color: Color(0xFF8D99AE),
                                    fontSize: 13,
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
      ],
    );
  }
}
