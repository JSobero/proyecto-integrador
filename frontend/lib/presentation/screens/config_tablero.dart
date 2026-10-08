import 'package:flutter/material.dart';
import '../../services/estudiantes_service.dart';
import '../widgets/custom_inputs.dart'; // Para PrimaryButton

class ConfigTableroScreen extends StatefulWidget {
  const ConfigTableroScreen({Key? key}) : super(key: key);

  @override
  _ConfigTableroScreenState createState() => _ConfigTableroScreenState();
}

class _ConfigTableroScreenState extends State<ConfigTableroScreen> {
  double _densidadVisual = 8;
  bool _ocultarTexto = false;
  bool _vibracionHaptica = true;
  double _tamanoFuente = 9.5;

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() => _cargando = true);
    try {
      final config = await EstudiantesService.obtenerConfiguracion();
      setState(() {
        _densidadVisual = (config['densidad_visual'] ?? 8).toDouble();
        _ocultarTexto = config['ocultar_texto'] ?? false;
        _vibracionHaptica = config['vibracion_haptica'] ?? true;
        _tamanoFuente = (config['tamano_fuente'] ?? 9.5).toDouble();
      });
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

  Future<void> _guardarConfiguracion() async {
    setState(() => _cargando = true);
    try {
      await EstudiantesService.guardarConfiguracion({
        'densidad_visual': _densidadVisual.toInt(),
        'ocultar_texto': _ocultarTexto,
        'vibracion_haptica': _vibracionHaptica,
        'tamano_fuente': _tamanoFuente,
      });
      if (mounted) {
        _mostrarMensaje('Ajustes clínicos guardados', esError: false);
        Navigator.pop(context);
      }
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

  void _mostrarMensaje(String texto, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError
            ? const Color(0xFFEF233C)
            : const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Accesibilidad Clínica',
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
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4361EE)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECCIÓN 1: MOTRICIDAD FINA ---
                    const Text(
                      '1. Motricidad Fina',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Ajusta el número de columnas para hacer los botones más grandes.',
                      style: TextStyle(color: Color(0xFF8D99AE)),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4361EE).withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(
                                Icons.grid_view_rounded,
                                color: Color(0xFF4361EE),
                              ),
                              Text(
                                '${_densidadVisual.toInt()} columnas máx.',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4361EE),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF4361EE),
                              inactiveTrackColor: const Color(0xFFE2E8F0),
                              thumbColor: const Color(0xFFFFB703),
                              trackHeight: 8.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 15.0,
                              ),
                            ),
                            child: Slider(
                              value: _densidadVisual,
                              min: 2,
                              max: 12,
                              divisions: 5,
                              label: _densidadVisual.round().toString(),
                              onChanged: (val) =>
                                  setState(() => _densidadVisual = val),
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gigante (2)',
                                style: TextStyle(
                                  color: Color(0xFF8D99AE),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Pequeño (12)',
                                style: TextStyle(
                                  color: Color(0xFF8D99AE),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- SECCIÓN 2: PERFIL NEURO-VISUAL ---
                    const Text(
                      '2. Perfil Neuro-Visual',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Evita la sobrecarga cognitiva en pacientes pre-lectores.',
                      style: TextStyle(color: Color(0xFF8D99AE)),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4361EE).withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text(
                              'Ocultar Textos',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Muestra solo la imagen del pictograma',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _ocultarTexto,
                            activeColor: const Color(0xFF10B981),
                            onChanged: (val) =>
                                setState(() => _ocultarTexto = val),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (!_ocultarTexto) ...[
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tamaño de letra',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_tamanoFuente.toStringAsFixed(1)} px',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4361EE),
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF4361EE),
                                inactiveTrackColor: const Color(0xFFE2E8F0),
                                thumbColor: const Color(0xFFFFB703),
                                trackHeight: 8.0,
                              ),
                              child: Slider(
                                value: _tamanoFuente,
                                min: 8.0,
                                max: 14.0,
                                divisions: 6,
                                onChanged: (val) =>
                                    setState(() => _tamanoFuente = val),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- SECCIÓN 3: PERFIL SENSORIAL ---
                    const Text(
                      '3. Perfil Sensorial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4361EE).withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Feedback Háptico',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Vibración física al presionar un botón',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _vibracionHaptica,
                        activeColor: const Color(0xFFF72585),
                        secondary: const Icon(
                          Icons.vibration_rounded,
                          color: Color(0xFFF72585),
                        ),
                        onChanged: (val) =>
                            setState(() => _vibracionHaptica = val),
                      ),
                    ),

                    const SizedBox(height: 40),
                    PrimaryButton(
                      text: 'GUARDAR AJUSTES CLÍNICOS',
                      isLoading: _cargando,
                      onPressed: _guardarConfiguracion,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
