import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/usuarios_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _passActualCtrl = TextEditingController();
  final _passNuevaCtrl = TextEditingController();
  // NUEVO CONTROLADOR:
  final _passConfirmarCtrl = TextEditingController();

  bool _cargando = true;
  int? _usuarioId;
  String _rol = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosLocales();
  }

  Future<void> _cargarDatosLocales() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usuarioId = prefs.getInt('usuario_id');
      _rol = prefs.getString('rol') ?? 'estudiante';
      _nombresCtrl.text = prefs.getString('nombres') ?? '';
      _apellidosCtrl.text = prefs.getString('apellidos') ?? '';
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usuarioId == null) return;

    // NUEVA VALIDACIÓN: Confirmar contraseña
    if (_passNuevaCtrl.text.isNotEmpty) {
      if (_passNuevaCtrl.text != _passConfirmarCtrl.text) {
        _mostrarError('Las nuevas contraseñas no coinciden');
        return;
      }
      if (_passActualCtrl.text.isEmpty) {
        _mostrarError('Ingresa tu contraseña actual para cambiarla');
        return;
      }
    }

    setState(() => _cargando = true);

    final resultado = await UsuariosService.actualizarPerfil(
      _usuarioId!,
      nombres: _nombresCtrl.text.trim(),
      apellidos: _apellidosCtrl.text.trim(),
      passwordActual: _passActualCtrl.text.isNotEmpty
          ? _passActualCtrl.text
          : null,
      nuevaPassword: _passNuevaCtrl.text.isNotEmpty
          ? _passNuevaCtrl.text
          : null,
    );

    setState(() => _cargando = false);

    if (!mounted) return;

    if (resultado['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Datos guardados con éxito!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      _mostrarError(resultado['error']);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFEF233C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos Básicos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      'Nombres',
                      Icons.person_rounded,
                      _nombresCtrl,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      'Apellidos',
                      Icons.person_outline_rounded,
                      _apellidosCtrl,
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Seguridad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Deja en blanco si no deseas cambiar tu contraseña.',
                      style: TextStyle(color: Color(0xFF8D99AE), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      'Contraseña Actual',
                      Icons.lock_outline_rounded,
                      _passActualCtrl,
                      esClave: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      'Nueva Contraseña',
                      Icons.lock_reset_rounded,
                      _passNuevaCtrl,
                      esClave: true,
                    ),
                    const SizedBox(height: 16),
                    // NUEVO CAMPO: Confirmar contraseña
                    _buildInputField(
                      'Confirmar Nueva Contraseña',
                      Icons.check_circle_outline_rounded,
                      _passConfirmarCtrl,
                      esClave: true,
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4361EE),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
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

  Widget _buildInputField(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    bool esClave = false,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: esClave,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4361EE)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
      ),
    );
  }
}
