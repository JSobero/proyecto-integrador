import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ConfigTableroScreen extends StatefulWidget {
  const ConfigTableroScreen({Key? key}) : super(key: key);

  @override
  _ConfigTableroScreenState createState() => _ConfigTableroScreenState();
}

class _ConfigTableroScreenState extends State<ConfigTableroScreen> {
  double _densidadVisual = 8;
  bool _cargando = true;
  int? _usuarioId;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    _usuarioId = prefs.getInt('usuario_id');

    if (_usuarioId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/estudiantes/$_usuarioId/configuracion/',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _densidadVisual = data['densidad_visual'].toDouble());
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarConfiguracion() async {
    setState(() => _cargando = true);
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/estudiantes/$_usuarioId/configuracion/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'densidad_visual': _densidadVisual.toInt()}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajustes guardados'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al guardar')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Ajustes del Tablero',
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Densidad Visual',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Limita la cantidad de pictogramas en pantalla para evitar sobrecarga sensorial en el estudiante.',
                      style: TextStyle(color: Color(0xFF8D99AE)),
                    ),
                    const SizedBox(height: 40),

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
                                '${_densidadVisual.toInt()} pictogramas máx.',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4361EE),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF4361EE),
                              inactiveTrackColor: const Color(0xFFE2E8F0),
                              thumbColor: const Color(0xFFFFB703),
                              overlayColor: const Color(
                                0xFFFFB703,
                              ).withOpacity(0.2),
                              trackHeight: 8.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 15.0,
                              ),
                            ),
                            child: Slider(
                              value: _densidadVisual,
                              min: 2,
                              max: 12,
                              divisions: 5, // (2, 4, 6, 8, 10, 12)
                              label: _densidadVisual.round().toString(),
                              onChanged: (val) =>
                                  setState(() => _densidadVisual = val),
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mínimo (2)',
                                style: TextStyle(
                                  color: Color(0xFF8D99AE),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Máximo (12)',
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
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _guardarConfiguracion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4361EE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
