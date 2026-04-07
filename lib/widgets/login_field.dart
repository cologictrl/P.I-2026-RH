import 'package:flutter/material.dart';
import 'package:rhos/palette.dart';

class LoginField extends StatelessWidget {
  final String textoDica;
  final bool campoSenha;
  final IconData? icone;
  final TextEditingController? controlador;
  final String? Function(String?)? validador;
  final TextInputType tipoTeclado;
  final TextInputAction? acaoTeclado;

  const LoginField({
    super.key,
    required this.textoDica,
    this.campoSenha = false,
    this.icone,
    this.controlador,
    this.validador,
    this.tipoTeclado = TextInputType.text,
    this.acaoTeclado,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: TextFormField(
        controller: controlador,
        validator: validador,
        keyboardType: tipoTeclado,
        textInputAction: acaoTeclado,
        style: const TextStyle(color: Palette.textColor2),
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
          hintText: textoDica,
          hintStyle: const TextStyle(
            color: Palette.textColor2, //Cor Texto
            fontWeight: FontWeight.bold, //Formatação Texto
            fontSize: 20, //Tamanho Texto
          ),
          suffixIcon: icone != null
              ? Icon(icone, color: Palette.textColor2)
              : null,
        ),
        obscureText: campoSenha,
      ),
    );
  }
}
