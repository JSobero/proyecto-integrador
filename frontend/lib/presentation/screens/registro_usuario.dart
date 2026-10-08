import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../widgets/custom_inputs.dart';

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
      await AuthService.registrarUsuario({
        'nombres': _nombresCtrl.text,
        'apellidos': _apellidosCtrl.text,
        'email': _emailCtrl.text,
        'dni': _dniCtrl.text,
        'rol': _rolSeleccionado,
        'password': _passwordCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada con éxito. Inicia sesión.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(
        () => _errorMensaje = e.toString().replaceAll('Exception: ', ''),
      );
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
            child: AuthCardContainer(
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
                  ErrorMessage(message: _errorMensaje!),

                ModernTextField(
                  controller: _nombresCtrl,
                  label: 'Nombres',
                  icon: Icons.badge_rounded,
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _apellidosCtrl,
                  label: 'Apellidos',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _emailCtrl,
                  label: 'Correo',
                  icon: Icons.email_rounded,
                  tipo: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _dniCtrl,
                  label: 'DNI',
                  icon: Icons.credit_card_rounded,
                  tipo: TextInputType.number,
                  maxLen: 8,
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _passwordCtrl,
                  label: 'Crear Contraseña',
                  icon: Icons.lock_rounded,
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
                      child: Text(
                        'Familiar / Apoyo en casa',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _rolSeleccionado = val!),
                ),
                const SizedBox(height: 30),
                PrimaryButton(
                  text: 'REGISTRARSE',
                  isLoading: _cargando,
                  onPressed: _registrarUsuario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
