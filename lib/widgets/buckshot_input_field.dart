import 'package:flutter/material.dart';

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
      style: const TextStyle(color: Colors.white),
      validator: validator, 
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), 
          borderSide: BorderSide.none
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility, 
                  color: Colors.grey[600]
                ), 
                onPressed: onToggleObscure
              ) 
            : null,
      ),
    );
  }
}