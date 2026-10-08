import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../widgets/custom_inputs.dart';
import 'main_screen.dart';
import 'registro_usuario.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;
  String? _errorMensaje;

  Future<void> _iniciarSesion() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Llena todos los campos')));
      return;
    }
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final data = await AuthService.iniciarSesion(
        _emailCtrl.text,
        _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(isLoggedIn: true, rol: data['rol']),
        ),
        (route) => false,
      );
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
                  Icons.lock_person_rounded,
                  size: 60,
                  color: Color(0xFF4361EE),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2B2D42),
                  ),
                ),
                const SizedBox(height: 30),

                if (_errorMensaje != null)
                  ErrorMessage(message: _errorMensaje!),

                ModernTextField(
                  controller: _emailCtrl,
                  label: 'Correo Electrónico',
                  icon: Icons.email_rounded,
                  tipo: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _passwordCtrl,
                  label: 'Contraseña (DNI)',
                  icon: Icons.password_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 30),

                PrimaryButton(
                  text: 'INGRESAR',
                  isLoading: _cargando,
                  onPressed: _iniciarSesion,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿No tienes una cuenta?",
                      style: TextStyle(color: Color(0xFF8D99AE)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegistroUsuario(),
                        ),
                      ),
                      child: const Text(
                        'Regístrate',
                        style: TextStyle(
                          color: Color(0xFF4361EE),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
