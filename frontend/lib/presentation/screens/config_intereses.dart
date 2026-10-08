import 'package:flutter/material.dart';
import '../../services/estudiantes_service.dart';

class ConfigIntereses extends StatefulWidget {
  const ConfigIntereses({Key? key}) : super(key: key);

  @override
  _ConfigInteresesState createState() => _ConfigInteresesState();
}

class _ConfigInteresesState extends State<ConfigIntereses> {
  final _palabraCtrl = TextEditingController();
  List<dynamic> _intereses = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerIntereses();
  }

  // --- LÓGICA DE ESTADO LIMPIA ---
  Future<void> _obtenerIntereses() async {
    setState(() => _cargando = true);
    try {
      final intereses = await EstudiantesService.obtenerIntereses();
      setState(() => _intereses = intereses);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _agregarInteres() async {
    if (_palabraCtrl.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);

    try {
      await EstudiantesService.agregarInteres(_palabraCtrl.text);
      _palabraCtrl.clear();
      await _obtenerIntereses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: const Color(0xFFEF233C),
          ),
        );
      }
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminarInteres(int id) async {
    setState(() => _cargando = true);
    try {
      await EstudiantesService.eliminarInteres(id);
      await _obtenerIntereses();
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  // --- INTERFAZ GRÁFICA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Mis Intereses',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2B2D42),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vocabulario Personalizado',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2D42),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Agrega palabras clave (Ej: gatos, trenes, música). Estas se añadirán automáticamente a tu tablero principal.',
                style: TextStyle(color: Color(0xFF8D99AE)),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _palabraCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nueva palabra...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      onSubmitted: (_) => _agregarInteres(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB703),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.black87,
                      ),
                      onPressed: _agregarInteres,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Expanded(
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4361EE),
                        ),
                      )
                    : _intereses.isEmpty
                    ? const Center(
                        child: Text(
                          'Aún no has agregado intereses',
                          style: TextStyle(color: Color(0xFF8D99AE)),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _intereses.length,
                        itemBuilder: (context, index) {
                          final interes = _intereses[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4361EE,
                                  ).withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFFB703),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      interes['palabra_clave']
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: Color(0xFF2B2D42),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFEF233C),
                                  ),
                                  onPressed: () =>
                                      _eliminarInteres(interes['id']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
