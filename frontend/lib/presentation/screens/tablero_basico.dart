import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../models/nodo_picto.dart';
import '../../data/vocabulario_asterics.dart';
import '../widgets/boton_pictograma.dart';

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

  List<NodoPicto> _rutaNavegacion = [];
  late final List<NodoPicto> _vocabularioBase;
  List<NodoPicto> _interesesDinamicos = [];

  @override
  void initState() {
    super.initState();
    _configurarMotorDeVoz();
    _vocabularioBase = VocabularioAsterics.obtenerArbol();
    _inicializarTablero();
  }

  Future<void> _inicializarTablero() async {
    await _cargarUrlsRecursivo(_vocabularioBase);
    await _cargarInteresesPersonales();
    if (mounted) setState(() => _cargandoIntereses = false);
  }

  Future<void> _cargarUrlsRecursivo(List<NodoPicto> nodos) async {
    List<Future> peticiones = [];
    for (var nodo in nodos) {
      // SOLO BUSCA EN LA API SI NO LE DIMOS UN ID EXACTO
      if (nodo.url.isEmpty) {
        final palabraCodificada = Uri.encodeComponent(nodo.palabraBusqueda);
        peticiones.add(
          http
              .get(
                Uri.parse(
                  '${ApiConfig.baseUrl}/pictogramas/generar/$palabraCodificada',
                ),
              )
              .then((res) {
                if (res.statusCode == 200) {
                  nodo.url = jsonDecode(res.body)['url'];
                }
              })
              .catchError((_) => null),
        );
      }

      if (nodo.esCarpeta && nodo.contenido != null) {
        peticiones.add(_cargarUrlsRecursivo(nodo.contenido!));
      }
    }
    await Future.wait(peticiones);
  }

  Future<void> _configurarMotorDeVoz() async {
    try {
      // Intentamos configurar español de España o Estados Unidos (los más estables en Android/iOS)
      bool isSpanishAvailable = await flutterTts.isLanguageAvailable("es-ES");

      if (isSpanishAvailable) {
        await flutterTts.setLanguage("es-ES");
      } else {
        await flutterTts.setLanguage(
          "es-US",
        ); // Respaldo latino/americano seguro
      }

      await flutterTts.setPitch(1.0); // Tono natural humano
      await flutterTts.setSpeechRate(
        0.42,
      ); // Velocidad pausada ideal para niños con TEA
      await flutterTts.awaitSpeakCompletion(false);
    } catch (e) {
      debugPrint("Error configurando el motor de voz: $e");
    }
  }

  Future<void> _cargarInteresesPersonales() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');
    if (usuarioId == null) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/estudiantes/$usuarioId/intereses/'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        List<NodoPicto> temporales = [];

        for (var item in data) {
          String palabra = item['palabra_clave'];
          temporales.add(
            NodoPicto(
              palabra: palabra.toUpperCase(),
              palabraBusqueda: palabra,
              colorFondo: Colors.white,
            ),
          );
        }
        await _cargarUrlsRecursivo(temporales);
        if (mounted) setState(() => _interesesDinamicos = temporales);
      }
    } catch (e) {
      debugPrint("Error cargando intereses");
    }
  }

  List<NodoPicto> get _vocabularioActual {
    if (_rutaNavegacion.isEmpty) {
      return [..._vocabularioBase, ..._interesesDinamicos];
    }
    return _rutaNavegacion.last.contenido ?? [];
  }

  void _tocarBoton(NodoPicto picto) {
    if (picto.esCarpeta && picto.contenido != null) {
      setState(() => _rutaNavegacion.add(picto));
      flutterTts.speak(picto.palabra);
    } else {
      if (picto.url.isNotEmpty) {
        _agregarAOracion({"palabra": picto.palabra, "url": picto.url});

        // ¡NUEVO! Habla la palabra inmediatamente al tocarla
        // La pasamos a minúsculas porque los motores TTS leen mejor así
        flutterTts.speak(picto.palabra.toLowerCase());
      }
    }
  }

  void _irAtras() {
    if (_rutaNavegacion.isNotEmpty)
      setState(() => _rutaNavegacion.removeLast());
  }

  Future<void> _hablarOracion() async {
    if (_oracionActual.isEmpty) return;
    String fraseCruda = _oracionActual
        .map((p) => p['palabra']!.toLowerCase())
        .join(" ");
    String fraseFinal = fraseCruda;
    try {
      final fraseCodificada = Uri.encodeComponent(fraseCruda);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/frases/conjugar/$fraseCodificada'),
      );
      if (response.statusCode == 200) {
        fraseFinal =
            jsonDecode(utf8.decode(response.bodyBytes))['msg'] ?? fraseCruda;
      }
    } catch (e) {
      debugPrint("Error conjugando");
    }
    await flutterTts.speak(fraseFinal);
  }

  Future<void> _generarPictogramaIA(String texto) async {
    if (texto.trim().isEmpty) return;
    setState(() => _buscandoIA = true);
    FocusScope.of(context).unfocus(); // Oculta el teclado nativo

    try {
      // 1. Dividir la frase en palabras individuales (ignorando dobles espacios)
      List<String> palabras = texto.trim().split(RegExp(r'\s+'));

      // 2. Disparar TODAS las búsquedas al servidor de forma simultánea (Paralelismo)
      List<Future<http.Response>> peticiones = palabras.map((p) {
        final palabraCodificada = Uri.encodeComponent(p);
        return http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/pictogramas/generar/$palabraCodificada',
          ),
        );
      }).toList();

      // 3. Esperar a que el backend resuelva todas las imágenes al mismo tiempo
      final respuestas = await Future.wait(peticiones);

      bool faltanConectores = false;

      // 4. Procesar las respuestas en el orden exacto en el que el usuario escribió la frase
      for (int i = 0; i < respuestas.length; i++) {
        if (respuestas[i].statusCode == 200) {
          final data = jsonDecode(respuestas[i].body);
          // Agrega la palabra a la barra y registra la analítica en la base de datos
          _agregarAOracion({"palabra": data['palabra'], "url": data['url']});
        } else {
          // Si el usuario escribió un conector como "al", "de", "que" y no tiene imagen,
          // simplemente lo saltamos para no romper la experiencia.
          faltanConectores = true;
        }
      }

      // 5. Feedback auditivo: Si logró armar la frase, que la lea automáticamente
      if (_oracionActual.isNotEmpty) {
        _hablarOracion();
      }

      // 6. Limpiamos la barra de búsqueda
      _buscadorCtrl.clear();

      if (faltanConectores && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se omitieron algunos conectores que no tienen imagen exacta',
            ),
            backgroundColor: Color(0xFF8D99AE),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión al buscar la frase')),
        );
      }
    } finally {
      if (mounted) setState(() => _buscandoIA = false);
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
    } catch (_) {}
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
    // --- LÓGICA RESPONSIVE (ADAPTABILIDAD DE PANTALLA) ---
    final double screenWidth = MediaQuery.of(context).size.width;

    int cantidadColumnas = 4; // Por defecto (Celulares)
    double proporcionTarjeta = 0.75;

    if (screenWidth >= 1000) {
      // Tablets grandes en horizontal o monitores Web
      cantidadColumnas = 10;
      proporcionTarjeta = 0.85;
    } else if (screenWidth >= 768) {
      // Tablets normales (iPad) o celulares grandes en horizontal
      cantidadColumnas = 8;
      proporcionTarjeta = 0.80;
    } else if (screenWidth >= 600) {
      // Tablets pequeñas en vertical
      cantidadColumnas = 6;
      proporcionTarjeta = 0.78;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            // --- BARRA CONSTRUCTORA ---
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4361EE).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _oracionActual.isEmpty
                        ? const Center(
                            child: Text(
                              'Arma tu frase aquí',
                              style: TextStyle(
                                color: Color(0xFF8D99AE),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(8),
                            itemCount: _oracionActual.length,
                            itemBuilder: (context, index) =>
                                _buildPictoEnBarra(_oracionActual[index]),
                          ),
                  ),
                  Container(
                    width: 60,
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFFE2E8F0)),
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
                            size: 30,
                          ),
                          onPressed: _hablarOracion,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- BUSCADOR JIT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: TextField(
                controller: _buscadorCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar palabras en la nube...',
                  prefixIcon: const Icon(
                    Icons.cloud_sync_rounded,
                    color: Color(0xFF4361EE),
                  ),
                  suffixIcon: _buscandoIA
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onSubmitted: _generarPictogramaIA,
              ),
            ),

            // --- NAVEGADOR DE CARPETAS ---
            if (_rutaNavegacion.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _rutaNavegacion.last.colorFondo.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _irAtras,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Color(0xFF2B2D42),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.folder_open_rounded,
                      color: Color(0xFF2B2D42),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _rutaNavegacion.last.palabra,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                  ],
                ),
              ),

            // --- TABLERO TÁCTIL RESPONSIVE ---
            Expanded(
              child: _cargandoIntereses
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4361EE),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(10.0),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            cantidadColumnas, // <-- VARIABLE DINÁMICA
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio:
                            proporcionTarjeta, // <-- VARIABLE DINÁMICA
                      ),
                      itemCount: _vocabularioActual.length,
                      itemBuilder: (context, index) {
                        return BotonPictograma(
                          pictoInfo: _vocabularioActual[index],
                          onTap: () => _tocarBoton(_vocabularioActual[index]),
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
      width: 65,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: CachedNetworkImage(imageUrl: picto['url']!),
            ),
          ),
          Text(
            picto['palabra']!,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2D42),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
