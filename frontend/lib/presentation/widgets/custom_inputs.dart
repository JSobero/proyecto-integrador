import 'package:flutter/material.dart';

class ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType tipo;
  final int? maxLen;
  final bool obscure;

  const ModernTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.tipo = TextInputType.text,
    this.maxLen,
    this.obscure = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        labelStyle: const TextStyle(color: Color(0xFF8D99AE)),
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

class PrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.isLoading = false,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4361EE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          shadowColor: const Color(0xFF4361EE).withOpacity(0.5),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}

class AuthCardContainer extends StatelessWidget {
  final List<Widget> children;
  const AuthCardContainer({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class ErrorMessage extends StatelessWidget {
  final String message;
  const ErrorMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF233C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF233C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFEF233C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
