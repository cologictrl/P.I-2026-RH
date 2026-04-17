import 'package:flutter/material.dart';
import 'package:rhos/palette.dart';

class CustomButton extends StatelessWidget {
  final String texto; // Texto
  final Color cor; // Cor de fundo
  final double largura; // Largura
  final double altura; // Altura
  final double tamanhoFonte; // Tamanho da fonte
  final VoidCallback? aoPressionar; // Ação de clique

  const CustomButton({
    super.key,
    required this.texto,
    required this.cor,
    required this.aoPressionar,
    this.largura = 360, // Valor padrão se não definir
    this.altura = 70, // Valor padrão se não definir
    this.tamanhoFonte = 30, // Valor padrão se não definir
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: aoPressionar,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(largura, altura),
        backgroundColor: cor, // Defina a Cor do botão
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // O arredondamento da borda
        ),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: tamanhoFonte,
          fontWeight: FontWeight.bold,
          color: Palette.textColor1, // Cor do texto do botão
        ),
      ),
    );
  }
}
