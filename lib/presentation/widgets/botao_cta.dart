// ============================================================
// botao_cta.dart
// Responsabilidade: Botao CTA padrao laranja do design system
// Camada: presentation
// ============================================================

import 'package:flutter/material.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/tema/app_estilos.dart';

class BotaoCta extends StatelessWidget {
  const BotaoCta({
    super.key,
    required this.label,
    required this.aoPresionar,
    this.carregando = false,
  });

  final String label;
  final VoidCallback? aoPresionar;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    // Ocupa a largura total e define a altura padrao do CTA
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        // Desabilita o botao enquanto houver carregamento
        onPressed: carregando ? null : aoPresionar,
        style: ElevatedButton.styleFrom(
          // Aplica as cores do sistema visual
          backgroundColor: AppCores.cta,
          foregroundColor: AppCores.fundoCard,
          disabledBackgroundColor: AppCores.cta.withAlpha(153),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        // Mostra progresso ou texto do botao conforme o estado
        child: carregando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  // Indicador branco sobre o fundo do CTA
                  color: AppCores.fundoCard,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label.toUpperCase(),
                style: AppEstilos.textoBotao,
              ),
      ),
    );
  }
}
