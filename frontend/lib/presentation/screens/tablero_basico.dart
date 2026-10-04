import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class TableroBasico extends StatefulWidget {
  const TableroBasico({Key? key}) : super(key: key);

  @override
  _TableroBasicoState createState() => _TableroBasicoState();
}

class _TableroBasicoState extends State<TableroBasico> {
  final List<Map<String, String>> _oracionActual = [];
  final TextEditingController _buscadorCtrl = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();

  bool _buscandoIA = false;
  bool _cargandoIntereses = true;
  int _densidadVisual = 12;

  // NUEVO: Las categorías ahora son dinámicas y pasan por la IA para asegurar la imagen correcta
  List<Map<String, String>> _categoriasBase = [];
  List<Map<String, String>> _interesesDinamicos = [];

  List<Map<String, String>> get _vocabularioTotal => [
    ..._categoriasBase,
    ..._interesesDinamicos,
  ];

  @override
  void initState() {
    super.initState();
    _configurarMotorDeVoz();
    _cargarVocabularioCompleto(); // Llama a la nueva función centralizada
  }

  Future<void> _configurarMotorDeVoz() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.1);
  }

  // --- CARGA DINÁMICA DEL VOCABULARIO BASE E INTERESES ---
  Future<void> _cargarVocabularioCompleto() async {
    setState(() => _cargandoIntereses = true);

    // 1. Cargar vocabulario funcional base usando la IA
    final palabrasBase = ["YO", "COMIDA", "FELIZ", "CASA", "GATO", "JUGAR"];
    List<Map<String, String>> baseTemporal = [];

    for (String palabra in palabrasBase) {
      try {
        final res = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/pictogramas/generar/${palabra.toLowerCase()}',
          ),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          baseTemporal.add({"palabra": palabra, "url": data['url']});
        }
      } catch (e) {
        debugPrint("Error cargando $palabra: $e");
      }
    }

    // 2. Comprobar sesión y cargar intereses
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) {
      if (mounted) {
        setState(() {
          _categoriasBase = baseTemporal;
          _interesesDinamicos = [];
          _densidadVisual = 12;
          _cargandoIntereses = false;
        });
      }
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/estudiantes/$usuarioId/intereses/'),
      );
      List<Map<String, String>> dinamicoTemporal = [];

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        for (var item in data) {
          String palabra = item['palabra_clave'];
          final pictoRes = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/pictogramas/generar/$palabra'),
          );
          if (pictoRes.statusCode == 200) {
            final pictoData = jsonDecode(pictoRes.body);
            dinamicoTemporal.add({
              "palabra": pictoData['palabra'].toString().toUpperCase(),
              "url": pictoData['url'],
            });
          }
        }
      }

      final configRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/estudiantes/$usuarioId/configuracion/'),
      );
      if (configRes.statusCode == 200) {
        _densidadVisual = jsonDecode(configRes.body)['densidad_visual'];
      }

      if (mounted) {
        setState(() {
          _categoriasBase = baseTemporal;
          _interesesDinamicos = dinamicoTemporal;
        });
      }
    } catch (e) {
      debugPrint("Error de conexión: $e");
    } finally {
      if (mounted) setState(() => _cargandoIntereses = false);
    }
  }

  Future<void> _hablarOracion() async {
    if (_oracionActual.isEmpty) return;

    String fraseCruda = _oracionActual
        .map((p) => p['palabra']!.toLowerCase())
        .join(" ");
    String fraseFinal = fraseCruda;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/frases/conjugar/$fraseCruda'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        fraseFinal = data['msg'] ?? fraseCruda;
      }
    } catch (e) {
      debugPrint("Error conjugando frase: $e");
    }
    await flutterTts.speak(fraseFinal);
  }

  Future<void> _generarPictogramaIA(String palabra) async {
    if (palabra.trim().isEmpty) return;

    setState(() => _buscandoIA = true);
    FocusScope.of(context).unfocus();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pictogramas/generar/$palabra'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _agregarAOracion({"palabra": data['palabra'], "url": data['url']});
        _buscadorCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró imagen para esta palabra'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error conectando al motor JIT')),
      );
    } finally {
      setState(() => _buscandoIA = false);
    }
  }

  Future<void> _registrarClickAnaliticas(String palabra) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');
    if (usuarioId == null) return;

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/estudiantes/$usuarioId/tracking/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'palabra': palabra}),
      );
    } catch (e) {
      debugPrint("Error de tracking en segundo plano: $e");
    }
  }

  void _agregarAOracion(Map<String, String> pictograma) {
    setState(() => _oracionActual.add(pictograma));
    _registrarClickAnaliticas(pictograma['palabra']!);
  }

  void _borrarUltimo() {
    if (_oracionActual.isNotEmpty) setState(() => _oracionActual.removeLast());
  }

  void _limpiarOracion() => setState(() => _oracionActual.clear());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 120,
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4361EE).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF4361EE).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _oracionActual.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Center(
                              child: Text(
                                'Toca las imágenes para armar tu frase',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF8D99AE),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: _oracionActual.length,
                            itemBuilder: (context, index) =>
                                _buildPictoEnBarra(_oracionActual[index]),
                          ),
                  ),
                  Container(
                    width: 70,
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFFE2E8F0), width: 2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.backspace_rounded,
                            color: Color(0xFFEF233C),
                          ),
                          onPressed: _borrarUltimo,
                          onLongPress: _limpiarOracion,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.volume_up_rounded,
                            color: Color(0xFF4361EE),
                            size: 32,
                          ),
                          onPressed: _hablarOracion,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 0.0,
              ),
              child: TextField(
                controller: _buscadorCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar palabras nuevas...',
                  hintStyle: const TextStyle(color: Color(0xFF8D99AE)),
                  prefixIcon: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFFFB703),
                  ),
                  suffixIcon: _buscandoIA
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF4361EE),
                          ),
                          onPressed: () =>
                              _generarPictogramaIA(_buscadorCtrl.text),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onSubmitted: _generarPictogramaIA,
              ),
            ),
            Expanded(
              child: _cargandoIntereses
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4361EE),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _vocabularioTotal.length > _densidadVisual
                          ? _densidadVisual
                          : _vocabularioTotal.length,
                      itemBuilder: (context, index) {
                        return BotonPictograma(
                          palabra: _vocabularioTotal[index]["palabra"]!,
                          imageUrl: _vocabularioTotal[index]["url"]!,
                          onTap: () =>
                              _agregarAOracion(_vocabularioTotal[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictoEnBarra(Map<String, String> picto) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: CachedNetworkImage(
                imageUrl: picto['url']!,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          Text(
            picto['palabra']!,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2D42),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class BotonPictograma extends StatefulWidget {
  final String palabra;
  final String imageUrl;
  final VoidCallback onTap;
  const BotonPictograma({
    Key? key,
    required this.palabra,
    required this.imageUrl,
    required this.onTap,
  }) : super(key: key);
  @override
  _BotonPictogramaState createState() => _BotonPictogramaState();
}

class _BotonPictogramaState extends State<BotonPictograma> {
  double _scale = 1.0;
  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.92);
  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, double value, child) =>
            Transform.scale(scale: value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4361EE).withOpacity(0.08),
                spreadRadius: 2,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 15.0,
                    left: 15.0,
                    right: 15.0,
                    bottom: 8.0,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4361EE),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.image_not_supported_rounded,
                      size: 40,
                      color: Color(0xFF8D99AE),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  widget.palabra,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2B2D42),
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
