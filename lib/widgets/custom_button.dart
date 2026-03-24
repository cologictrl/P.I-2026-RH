import 'package:flutter/material.dart';
import 'package:rhos/palette.dart';

class CustomButton extends StatelessWidget {
  final String text; // Texto
  final Color color; // Cor de fundo
  final double width; // Largura
  final double height; // Altura
  final double fontSize; // Tamanho da fonte
  final VoidCallback onPressed; // Ação de clique

  const CustomButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
    this.width = 360, // Valor padrão se não definir
    this.height = 70, // Valor padrão se não definir
    this.fontSize = 30, // Valor padrão se não definir
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(width, height),
        backgroundColor: color, // Defina a Cor do botão
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // O arredondamento da borda
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Palette.textColor1, // Cor do texto do botão
        ),
      ),
    );
  }
}
