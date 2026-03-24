import 'package:flutter/material.dart';
import 'package:rhos/palette.dart';

class LoginField extends StatelessWidget {
  final String hintText;
  final bool isPasswordField;
  final IconData? icon;

  const LoginField({super.key, required this.hintText, this.isPasswordField = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(constraints: const BoxConstraints(maxWidth: 350),
    child: TextFormField(
      style: const TextStyle(
        color: Palette.textColor2,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Palette.backgroundColor2, //Cor de fundo
        contentPadding: const EdgeInsets.all(15),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Palette.backgroundColor2, //Cor borda selecionado
            width: 3,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Palette.textColor2, //Cor Texto
          fontWeight: FontWeight.bold, //Formatação Texto
          fontSize: 20, //Tamanho Texto
        ),
        suffixIcon: icon != null ? Icon(icon, color: Palette.textColor2) : null,
      ),
      obscureText: isPasswordField,
    ),);
  }
}
