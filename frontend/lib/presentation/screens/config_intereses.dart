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

  // --- NUEVO: CUADRO DE DIÁLOGO DE CONFIRMACIÓN ---
  Future<bool> _mostrarDialogoConfirmacion() async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFEF233C)),
                SizedBox(width: 10),
                Text(
                  'Eliminar interés',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta palabra de tu vocabulario personal?',
              style: TextStyle(color: Color(0xFF64748B), height: 1.4),
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
                  backgroundColor: const Color(0xFFEF233C).withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sí, eliminar',
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

  // --- FUNCIÓN DE ELIMINAR ACTUALIZADA ---
  Future<void> _eliminarInteres(int id) async {
    // 1. Pausa la ejecución y espera la respuesta del usuario
    bool confirmar = await _mostrarDialogoConfirmacion();

    // 2. Si el usuario tocó "Cancelar" o cerró el cuadro, abortamos
    if (!confirmar) return;

    // 3. Si dijo que sí, procedemos a borrar
    setState(() => _cargando = true);
    try {
      await EstudiantesService.eliminarInteres(id);
      await _obtenerIntereses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubo un error al intentar eliminar'),
            backgroundColor: Color(0xFFEF233C),
          ),
        );
      }
      setState(() => _cargando = false);
    }
  }

  // --- INTERFAZ GRÁFICA RENOVADA ---
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
        child: Column(
          children: [
            // 1. TARJETA HERO (Anclaje visual superior)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10.0,
              ),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4361EE).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      SizedBox(width: 10),
                      Text(
                        'Vocabulario Personalizado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Agrega palabras clave (Ej: gatos, trenes, música). Estas se añadirán automáticamente a tu tablero principal.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // 2. BARRA DE INGRESO UNIFICADA
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _palabraCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nueva palabra...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        onSubmitted: (_) => _agregarInteres(),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB703),
                        borderRadius: BorderRadius.circular(10),
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
              ),
            ),

            const SizedBox(height: 10),

            // 3. LISTA DE TARJETAS ESTRUCTURADAS
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4361EE),
                      ),
                    )
                  : _intereses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.interests_rounded,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Aún no has agregado intereses',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 10.0,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _intereses.length,
                      itemBuilder: (context, index) {
                        final interes = _intereses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          // ClipRRect para redondear el borde lateral que crearemos
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Color(
                                      0xFFFFB703,
                                    ), // Acento visual lateral
                                    width: 5,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFFB703),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        interes['palabra_clave']
                                            .toString()
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
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
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
