import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';

class RegistroUsuario extends StatefulWidget {
  const RegistroUsuario({Key? key}) : super(key: key);

  @override
  _RegistroUsuarioState createState() => _RegistroUsuarioState();
}

class _RegistroUsuarioState extends State<RegistroUsuario> {
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // CORRECCIÓN: El rol por defecto ahora es 'estudiante'
  String _rolSeleccionado = 'estudiante';

  bool _cargando = false;
  String? _errorMensaje;

  Future<void> _registrarUsuario() async {
    setState(() => _errorMensaje = null);

    if (_nombresCtrl.text.isEmpty ||
        _apellidosCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _dniCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty) {
      setState(() => _errorMensaje = 'Todos los campos son requeridos');
      return;
    }
    if (_dniCtrl.text.length != 8) {
      setState(() => _errorMensaje = 'El DNI debe contener 8 dígitos');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(
        () => _errorMensaje = 'La contraseña debe tener al menos 6 caracteres',
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombres': _nombresCtrl.text,
          'apellidos': _apellidosCtrl.text,
          'email': _emailCtrl.text,
          'dni': _dniCtrl.text,
          'rol': _rolSeleccionado, // Aquí se enviará 'estudiante' o 'terapeuta'
          'password': _passwordCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada con éxito. Inicia sesión.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        if (!mounted) return;
        Navigator.pop(context);
      } else if (response.statusCode == 422) {
        final errorList = jsonDecode(response.body)['detail'];
        setState(
          () => _errorMensaje = 'Error en los datos: ${errorList[0]['msg']}',
        );
      } else {
        setState(() => _errorMensaje = jsonDecode(response.body)['detail']);
      }
    } catch (e) {
      setState(() => _errorMensaje = 'Error de red. Verifica tu conexión.');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2B2D42),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4361EE).withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add_rounded,
                    size: 60,
                    color: Color(0xFF4361EE),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Registro para Estudiantes y Docentes',
                    style: TextStyle(color: Color(0xFF8D99AE)),
                  ),
                  const SizedBox(height: 25),

                  if (_errorMensaje != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF233C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMensaje!,
                        style: const TextStyle(
                          color: Color(0xFFEF233C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  _buildModernTextField(
                    _nombresCtrl,
                    'Nombres',
                    Icons.badge_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    _apellidosCtrl,
                    'Apellidos',
                    Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    _emailCtrl,
                    'Correo Electrónico',
                    Icons.email_rounded,
                    tipo: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    _dniCtrl,
                    'DNI',
                    Icons.credit_card_rounded,
                    tipo: TextInputType.number,
                    maxLen: 8,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    _passwordCtrl,
                    'Crear Contraseña',
                    Icons.lock_rounded,
                    obscure: true,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _rolSeleccionado,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF4361EE),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Rol del Usuario',
                      prefixIcon: const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFF4361EE),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    // CORRECCIÓN: Opciones del Dropdown actualizadas a la nueva lógica
                    items: const [
                      DropdownMenuItem(
                        value: 'estudiante',
                        child: Text(
                          'Estudiante / Alumno',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'terapeuta',
                        child: Text(
                          'Terapeuta / Docente',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'familiar',
                        child: Text('Familiar / Apoyo en casa'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _rolSeleccionado = val!),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4361EE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      child: _cargando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'REGISTRARSE',
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
        ),
      ),
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType tipo = TextInputType.text,
    int? maxLen,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      maxLength: maxLen,
      obscureText: obscure,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF2B2D42),
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        prefixIcon: Icon(icon, color: const Color(0xFF4361EE)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
