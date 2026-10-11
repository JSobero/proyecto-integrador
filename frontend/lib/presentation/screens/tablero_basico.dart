import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Para leer archivos File

import '../../services/motor_ia_service.dart';
import '../../services/estudiantes_service.dart';
import '../../models/nodo_picto.dart';
import '../../data/vocabulario_asterics.dart';
import '../widgets/boton_pictograma.dart';
import '../../services/offline_service.dart';

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

  // Ya no bloquearemos la pantalla completa
  bool _sincronizandoFondo = false;

  List<NodoPicto> _rutaNavegacion = [];
  late final List<NodoPicto> _vocabularioBase;
  List<NodoPicto> _interesesDinamicos = [];

  @override
  void initState() {
    super.initState();
    _configurarMotorDeVoz();
    _vocabularioBase = VocabularioAsterics.obtenerArbol();
    _inicializarCargaFantasma(); // Método no bloqueante
  }

  // --- LÓGICA DE CARGA EN SEGUNDO PLANO (LAZY LOADING) ---
  Future<void> _inicializarCargaFantasma() async {
    final prefs = await SharedPreferences.getInstance();
    String cacheString = prefs.getString('cache_urls_arasaac') ?? '{}';
    Map<String, dynamic> cacheUrls = jsonDecode(cacheString);

    List<NodoPicto> nodosPendientes = [];
    _inyectarCacheOExtraerPendientes(
      _vocabularioBase,
      cacheUrls,
      nodosPendientes,
    );

    // Carga los intereses de inmediato
    await _cargarInteresesPersonales(cacheUrls, prefs);

    if (nodosPendientes.isEmpty)
      return; // Todo está en caché, no hay nada que hacer

    // Si faltan imágenes, empezamos a descargarlas en la sombra
    setState(() => _sincronizandoFondo = true);

    int tamanioLote = 8; // Lotes pequeños para no asfixiar el celular
    for (int i = 0; i < nodosPendientes.length; i += tamanioLote) {
      int fin = (i + tamanioLote < nodosPendientes.length)
          ? i + tamanioLote
          : nodosPendientes.length;
      List<NodoPicto> loteActual = nodosPendientes.sublist(i, fin);

      List<Future> peticiones = loteActual.map((nodo) {
        return MotorIAService.obtenerImagenJit(nodo.palabraBusqueda).then((
          urlInternet,
        ) async {
          if (urlInternet != null) {
            // ¡MAGIA OFFLINE! Descargamos y guardamos la ruta física en lugar de la URL web
            String? rutaLocal = await OfflineService.guardarImagenLocal(
              nodo.palabraBusqueda,
              urlInternet,
            );

            if (rutaLocal != null) {
              nodo.url = rutaLocal;
              cacheUrls[nodo.palabraBusqueda] = rutaLocal;
            }
          }
        });
      }).toList();

      await Future.wait(peticiones);

      // Actualizamos la UI en cada lote. Las imágenes irán "apareciendo" solas.
      if (mounted) setState(() {});
    }

    // Al terminar, guardamos el nuevo caché
    await prefs.setString('cache_urls_arasaac', jsonEncode(cacheUrls));
    if (mounted) setState(() => _sincronizandoFondo = false);
  }

  void _inyectarCacheOExtraerPendientes(
    List<NodoPicto> nodos,
    Map<String, dynamic> cacheUrls,
    List<NodoPicto> pendientes,
  ) {
    for (var nodo in nodos) {
      if (nodo.url.isEmpty) {
        if (cacheUrls.containsKey(nodo.palabraBusqueda)) {
          nodo.url = cacheUrls[nodo.palabraBusqueda];
        } else {
          pendientes.add(nodo);
        }
      }
      if (nodo.esCarpeta && nodo.contenido != null) {
        _inyectarCacheOExtraerPendientes(
          nodo.contenido!,
          cacheUrls,
          pendientes,
        );
      }
    }
  }

  Future<void> _cargarInteresesPersonales(
    Map<String, dynamic> cacheUrls,
    SharedPreferences prefs,
  ) async {
    try {
      final intereses = await EstudiantesService.obtenerIntereses();
      List<NodoPicto> temporales = intereses.map((item) {
        String palabra = item['palabra_clave'];
        return NodoPicto(
          palabra: palabra.toUpperCase(),
          palabraBusqueda: palabra,
          colorFondo: Colors.white,
        );
      }).toList();

      List<Future> peticiones = [];
      bool huboNuevos = false;

      for (var nodo in temporales) {
        if (cacheUrls.containsKey(nodo.palabraBusqueda)) {
          nodo.url = cacheUrls[nodo.palabraBusqueda];
        } else {
          peticiones.add(
            MotorIAService.obtenerImagenJit(nodo.palabraBusqueda).then((url) {
              if (url != null) {
                nodo.url = url;
                cacheUrls[nodo.palabraBusqueda] = url;
                huboNuevos = true;
              }
            }),
          );
        }
      }

      if (peticiones.isNotEmpty) {
        await Future.wait(peticiones);
        if (huboNuevos)
          await prefs.setString('cache_urls_arasaac', jsonEncode(cacheUrls));
      }

      if (mounted) setState(() => _interesesDinamicos = temporales);
    } catch (_) {}
  }

  Future<void> _configurarMotorDeVoz() async {
    try {
      bool isSpanishAvailable = await flutterTts.isLanguageAvailable("es-ES");
      await flutterTts.setLanguage(isSpanishAvailable ? "es-ES" : "es-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.42);
      await flutterTts.awaitSpeakCompletion(false);
    } catch (e) {
      debugPrint("Error configurando TTS");
    }
  }

  List<NodoPicto> get _vocabularioActual {
    return _rutaNavegacion.isEmpty
        ? [..._vocabularioBase, ..._interesesDinamicos]
        : _rutaNavegacion.last.contenido ?? [];
  }

  void _tocarBoton(NodoPicto picto) {
    if (picto.esCarpeta && picto.contenido != null) {
      setState(() => _rutaNavegacion.add(picto));
      flutterTts.speak(picto.palabra);
    } else if (picto.url.isNotEmpty) {
      _agregarAOracion({"palabra": picto.palabra, "url": picto.url});
      flutterTts.speak(picto.palabra.toLowerCase());
    }
  }

  void _agregarAOracion(Map<String, String> pictograma) {
    setState(() => _oracionActual.add(pictograma));
    EstudiantesService.registrarTrackingClinico(pictograma['palabra']!);
  }

  Future<void> _hablarOracion() async {
    if (_oracionActual.isEmpty) return;
    String fraseCruda = _oracionActual
        .map((p) => p['palabra']!.toLowerCase())
        .join(" ");
    String fraseFinal = await MotorIAService.conjugarFrase(fraseCruda);
    await flutterTts.speak(fraseFinal);
  }

  Future<void> _generarPictogramaIA(String texto) async {
    if (texto.trim().isEmpty) return;
    setState(() => _buscandoIA = true);
    FocusScope.of(context).unfocus();

    try {
      List<String> palabras = texto.trim().split(RegExp(r'\s+'));
      List<Future<String?>> peticiones = palabras
          .map((p) => MotorIAService.obtenerImagenJit(p))
          .toList();
      final urls = await Future.wait(peticiones);

      bool faltanConectores = false;
      for (int i = 0; i < urls.length; i++) {
        if (urls[i] != null) {
          _agregarAOracion({
            "palabra": palabras[i].toUpperCase(),
            "url": urls[i]!,
          });
        } else {
          faltanConectores = true;
        }
      }

      if (_oracionActual.isNotEmpty) _hablarOracion();
      _buscadorCtrl.clear();

      if (faltanConectores && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se omitieron conectores sin imagen'),
            backgroundColor: Color(0xFF8D99AE),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _buscandoIA = false);
    }
  }

  // --- INTERFAZ GRÁFICA ---
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    int cantidadColumnas = screenWidth >= 1000
        ? 10
        : screenWidth >= 768
        ? 8
        : screenWidth >= 600
        ? 6
        : 4;
    double proporcionTarjeta = screenWidth >= 1000
        ? 0.85
        : screenWidth >= 768
        ? 0.80
        : screenWidth >= 600
        ? 0.78
        : 0.75;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            // BARRA SUPERIOR (Indicador de sincronización en segundo plano)
            if (_sincronizandoFondo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFFFB703).withOpacity(0.2),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFB703),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sincronizando nuevo vocabulario...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2B2D42),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // BARRA CONSTRUCTORA
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
                          onPressed: () {
                            if (_oracionActual.isNotEmpty)
                              setState(() => _oracionActual.removeLast());
                          },
                          onLongPress: () =>
                              setState(() => _oracionActual.clear()),
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

            // BUSCADOR EN LA NUBE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: TextField(
                controller: _buscadorCtrl,
                onSubmitted: _generarPictogramaIA,
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
              ),
            ),

            // NAVEGADOR DE CARPETAS
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
                      onTap: () {
                        if (_rutaNavegacion.isNotEmpty)
                          setState(() => _rutaNavegacion.removeLast());
                      },
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

            // TABLERO TÁCTIL (Se dibuja de inmediato)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10.0),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cantidadColumnas,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: proporcionTarjeta,
                ),
                itemCount: _vocabularioActual.length,
                itemBuilder: (context, index) => BotonPictograma(
                  pictoInfo: _vocabularioActual[index],
                  onTap: () => _tocarBoton(_vocabularioActual[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictoEnBarra(Map<String, String> picto) {
    return Container(
      constraints: const BoxConstraints(minWidth: 65, maxWidth: 100),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
              // Reemplaza el widget de CachedNetworkImage por este código:
              child: picto['url']!.startsWith('http')
                  // Si por algún motivo sigue siendo web, usa red
                  ? CachedNetworkImage(imageUrl: picto['url']!)
                  // Si ya está descargada en el celular, usa el archivo físico (100% Offline)
                  : Image.file(File(picto['url']!), fit: BoxFit.contain),
            ),
          ),
          Text(
            picto['palabra']!,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2D42),
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
