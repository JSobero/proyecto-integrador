import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback (alternativa nativa)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/nodo_picto.dart';

class BotonPictograma extends StatefulWidget {
  final NodoPicto pictoInfo;
  final VoidCallback onTap;

  const BotonPictograma({
    Key? key,
    required this.pictoInfo,
    required this.onTap,
  }) : super(key: key);

  @override
  _BotonPictogramaState createState() => _BotonPictogramaState();
}

class _BotonPictogramaState extends State<BotonPictograma> {
  double _scale = 1.0;
  bool _ocultarTexto = false;
  bool _hapticaActiva = true;
  double _tamanoFuente = 9.5;

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
  }

  Future<void> _cargarAjustes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ocultarTexto = prefs.getBool('cfg_ocultar_texto') ?? false;
      _hapticaActiva = prefs.getBool('cfg_haptica') ?? true;
      _tamanoFuente = prefs.getDouble('cfg_fuente') ?? 9.5;
    });
  }

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.92);

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);

    // --- ACCESIBILIDAD: FEEDBACK SENSORIAL (HÁPTICA) ---
    if (_hapticaActiva) {
      HapticFeedback.lightImpact(); // Genera una vibración nativa rápida al tocar
    }

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
            color: widget.pictoInfo.colorFondo,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: _ocultarTexto
                        ? 1
                        : 5, // Si se oculta el texto, la imagen ocupa el 100%
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 8.0,
                        left: 8.0,
                        right: 8.0,
                        bottom: _ocultarTexto ? 8.0 : 2.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: widget.pictoInfo.url.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: widget.pictoInfo.url,
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.grey,
                                    ),
                              ),
                      ),
                    ),
                  ),

                  // --- ACCESIBILIDAD: PERFIL NEURO-VISUAL ---
                  if (!_ocultarTexto)
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          widget.pictoInfo.palabra,
                          style: TextStyle(
                            fontSize: _tamanoFuente, // Tamaño dinámico
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2B2D42),
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.pictoInfo.esCarpeta)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: Colors.white,
                      size: 12,
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
