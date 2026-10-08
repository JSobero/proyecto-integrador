import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tablero_basico.dart';
import 'login.dart';
import '../widgets/modal_unirse.dart';
import 'config_intereses.dart';
import 'crear_aula.dart';
import 'mis_aulas.dart';
import 'panel_estudiante.dart';
import 'config_tablero.dart';
import 'rutinas_screen.dart';
import 'bandeja_familiar.dart';
import 'panel_admin.dart';

class MainScreen extends StatefulWidget {
  final bool isLoggedIn;
  final String rol;

  const MainScreen({Key? key, required this.isLoggedIn, required this.rol})
    : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Key _tableroKey = UniqueKey();
  late bool _isLoggedIn;
  late String _rol;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.isLoggedIn;
    _rol = widget.rol;
  }

  void _recargarTablero() {
    setState(() => _tableroKey = UniqueKey());
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(isLoggedIn: false, rol: 'invitado'),
        ),
        (route) => false,
      );
    }
  }

  void _navegarA(Widget pantalla) async {
    Navigator.pop(context); // Cierra el Drawer
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    _recargarTablero(); // Si la configuración cambió, el tablero se recarga
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comunicador SAAC',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2B2D42),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF4F7FC),
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  if (!_isLoggedIn)
                    _buildDrawerItem(Icons.login_rounded, 'Iniciar Sesión', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    })
                  else ...[
                    // Opciones de Administrador
                    if (_rol == 'admin')
                      _buildDrawerItem(
                        Icons.admin_panel_settings_rounded,
                        'Gestión de Usuarios',
                        () => _navegarA(const PanelAdminScreen()),
                        color: const Color(0xFF3A0CA3),
                      ),

                    // Opciones de Docente/Terapeuta
                    if (_rol == 'docente' || _rol == 'terapeuta') ...[
                      _buildDrawerItem(
                        Icons.group_add_rounded,
                        'Crear Aula',
                        () => _navegarA(const CrearAulaScreen()),
                      ),
                      _buildDrawerItem(
                        Icons.school_rounded,
                        'Mis Aulas',
                        () => _navegarA(const MisAulasScreen()),
                      ),
                    ],

                    // Opciones de Estudiante
                    if (_rol == 'estudiante') ...[
                      _buildDrawerItem(
                        Icons.dashboard_customize_rounded,
                        'Mi Espacio / Clases',
                        () => _navegarA(const PanelEstudiante()),
                      ),
                      _buildDrawerItem(
                        Icons.format_list_numbered_rounded,
                        'Mis Rutinas',
                        () async {
                          final prefs = await SharedPreferences.getInstance();
                          final id = prefs.getInt('usuario_id') ?? 0;
                          _navegarA(
                            RutinasScreen(
                              estudianteId: id,
                              nombreEstudiante: 'Mi Perfil',
                              isDocente: false,
                            ),
                          );
                        },
                      ),
                    ],

                    // Opciones Familiares
                    if (_rol == 'familiar') ...[
                      _buildDrawerItem(
                        Icons.sensor_door_rounded,
                        'Unirse a Clase',
                        () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const ModalUnirseClase(),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        Icons.child_care_rounded,
                        'Actividad de mi Niño',
                        () => _navegarA(const BandejaFamiliarScreen()),
                        color: const Color(0xFFF72585),
                      ),
                    ],

                    // Ajustes Generales
                    if (_rol != 'admin') ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      _buildDrawerItem(
                        Icons.star_rounded,
                        'Intereses (Fringe Words)',
                        () => _navegarA(const ConfigIntereses()),
                        color: const Color(0xFFFFB703),
                      ),
                      _buildDrawerItem(
                        Icons.tune_rounded,
                        'Ajustes del Tablero',
                        () => _navegarA(const ConfigTableroScreen()),
                        color: const Color(0xFF10B981),
                      ),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(),
                    ),
                    _buildDrawerItem(
                      Icons.logout_rounded,
                      'Cerrar Sesión',
                      _cerrarSesion,
                      color: const Color(0xFFEF233C),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TableroBasico(key: _tableroKey),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF4361EE).withOpacity(0.1),
            child: Icon(
              _isLoggedIn ? Icons.account_circle : Icons.face_rounded,
              size: 45,
              color: const Color(0xFF4361EE),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _isLoggedIn ? 'Modo: ${_rol.toUpperCase()}' : 'Modo Invitado',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2B2D42),
            ),
          ),
          if (!_isLoggedIn)
            const Text(
              'Tablero básico activado',
              style: TextStyle(color: Color(0xFF8D99AE)),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = const Color(0xFF4361EE),
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: title == 'Cerrar Sesión' ? color : const Color(0xFF2B2D42),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onTap: onTap,
    );
  }
}
