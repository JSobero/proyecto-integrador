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
  String _nombreUsuario = ''; // NUEVO: Variable para el nombre real

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.isLoggedIn;
    _rol = widget.rol;
    _cargarDatosUsuario(); // NUEVO: Dispara la búsqueda del nombre
  }

  // --- NUEVA FUNCIÓN: Obtener el nombre del usuario de la memoria ---
  Future<void> _cargarDatosUsuario() async {
    if (_isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // Busca las claves más comunes. Asegúrate de que en tu login.dart
        // estés guardando el nombre con uno de estos nombres (ej. prefs.setString('nombre', ...))
        _nombreUsuario =
            prefs.getString('nombres') ??
            prefs.getString('nombre_usuario') ??
            'Usuario';
      });
    }
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
            _buildDrawerHeader(), // El nuevo Header rediseñado
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                physics:
                    const BouncingScrollPhysics(), // Efecto de rebote moderno
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
                        child: Divider(color: Color(0xFFE2E8F0)),
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
                      child: Divider(color: Color(0xFFE2E8F0)),
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

  // --- REDISEÑO PREMIUM DEL HEADER ---
  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 65, bottom: 30, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4361EE).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de perfil con borde blanco resaltado
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFF4F7FC),
              child: Icon(
                _isLoggedIn ? Icons.person_rounded : Icons.face_rounded,
                size: 40,
                color: const Color(0xFF4361EE),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // NOMBRE REAL DEL USUARIO
          Text(
            _isLoggedIn
                ? (_nombreUsuario.isNotEmpty ? _nombreUsuario : 'Hola, Usuario')
                : 'Modo Invitado',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // BADGE (Píldora) DE ROL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.2,
              ), // Fondo translúcido elegante
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              _isLoggedIn ? _rol.toUpperCase() : 'TABLERO BÁSICO',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REDISEÑO SUTIL DE LOS ITEMS DEL MENÚ ---
  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = const Color(0xFF4361EE),
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 5,
      ), // Separación extra entre opciones
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(
            10,
          ), // Un poco más grande el cuadro del icono
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: title == 'Cerrar Sesión' ? color : const Color(0xFF2B2D42),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: onTap,
        splashColor: color.withOpacity(0.1),
        hoverColor: color.withOpacity(0.05),
      ),
    );
  }
}
