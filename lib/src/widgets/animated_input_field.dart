import 'package:flutter/material.dart';

class AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? icon;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;

  const AnimatedInputField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.icon,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: validator,
    );
  }
}
