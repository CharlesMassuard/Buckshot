import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuckshotInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final bool isObscured;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator; 

  const BuckshotInputField({
    super.key, 
    required this.controller, 
    required this.hintText, 
    this.isPassword = false, 
    this.isObscured = false, 
    this.onToggleObscure,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? isObscured : false,
      style: GoogleFonts.jura(color: Colors.white, fontSize: 16),
      validator: validator, 
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF161224),
        hintText: hintText,
        hintStyle: GoogleFonts.jura(color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: Colors.white10, width: 1)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: Colors.white10, width: 1)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1)
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ), 
                onPressed: onToggleObscure
              ) 
            : null,
      ),
    );
  }
}