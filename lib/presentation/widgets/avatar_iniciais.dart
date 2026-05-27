// ============================================================
// avatar_iniciais.dart
// Responsabilidade: Widget de avatar circular com iniciais do nome
// Camada: presentation
// ============================================================

import 'package:flutter/material.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/utils/formatadores.dart';

class AvatarIniciais extends StatelessWidget {
  // Construtor do avatar com iniciais
  const AvatarIniciais({
    super.key,
    required this.nome,
    this.radius = 18,
    this.backgroundColor = AppCores.primaria,
    this.textColor = AppCores.textoClaro,
  });

  final String nome;
  final double radius;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    // Calcula as iniciais e o tamanho proporcional do texto
    final iniciais = Formatadores.iniciais(nome);
    final fontSize = radius * 0.75;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        iniciais,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
