import 'package:flutter/material.dart';
import '../../services/aulas_service.dart';
import '../widgets/custom_inputs.dart'; // Importa nuestros inputs reutilizables

class CrearAulaScreen extends StatefulWidget {
  const CrearAulaScreen({Key? key}) : super(key: key);

  @override
  _CrearAulaScreenState createState() => _CrearAulaScreenState();
}

class _CrearAulaScreenState extends State<CrearAulaScreen> {
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  bool _cargando = false;

  Future<void> _crearAula() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _mostrarMensaje('El nombre es obligatorio', esError: true);
      return;
    }

    setState(() => _cargando = true);
    try {
      await AulasService.crearAula(_nombreCtrl.text, _descripcionCtrl.text);
      if (mounted) {
        _mostrarMensaje('¡Clase creada con éxito!', esError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        _mostrarMensaje(
          e.toString().replaceAll("Exception: ", ""),
          esError: true,
        );
    } finally {
      if (mounted) setState(() => _cargando = false);
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
          'Nueva Clase',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4361EE).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    size: 60,
                    color: Color(0xFF4361EE),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Nombre del Aula',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2D42),
                ),
              ),
              const SizedBox(height: 10),
              ModernTextField(
                controller: _nombreCtrl,
                label: 'Ej: Terapia de Lenguaje A',
                icon: Icons.class_rounded,
              ),

              const SizedBox(height: 20),
              const Text(
                'Descripción (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2D42),
                ),
              ),
              const SizedBox(height: 10),

              // TextField multilínea (No usamos ModernTextField aquí porque es de 3 líneas)
              TextField(
                controller: _descripcionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Detalles de la clase...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              PrimaryButton(
                text: 'CREAR CLASE',
                isLoading: _cargando,
                onPressed: _crearAula,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
