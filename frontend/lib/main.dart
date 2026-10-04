import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String rol = prefs.getString('rol') ?? 'invitado';

  runApp(SaacApp(isLoggedIn: isLoggedIn, rol: rol));
}

class SaacApp extends StatelessWidget {
  final bool isLoggedIn;
  final String rol;
  const SaacApp({Key? key, required this.isLoggedIn, required this.rol})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAAC UTP',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4361EE)),
      ),
      home: MainScreen(isLoggedIn: isLoggedIn, rol: rol),
      debugShowCheckedModeBanner: false,
    );
  }
}
