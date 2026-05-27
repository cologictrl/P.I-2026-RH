// ============================================================
// rhos_bottom_nav.dart
// Responsabilidade: BottomNavigationBar padrao do app RH-OS
// Camada: presentation
// ============================================================

import 'package:flutter/material.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/tema/app_cores.dart';

class RhosBottomNav extends StatelessWidget {
  // Construtor da barra inferior
  const RhosBottomNav({
    super.key,
    required this.indiceAtual,
    required this.aoMudar,
  });

  final int indiceAtual;
  final ValueChanged<int> aoMudar;

  @override
  Widget build(BuildContext context) {
    // Monta a navegacao inferior com abas principais
    return BottomNavigationBar(
      currentIndex: indiceAtual,
      onTap: aoMudar,
      backgroundColor: AppCores.primaria,
      selectedItemColor: AppCores.cta,
      unselectedItemColor: AppCores.textoClaro,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: AppStrings.navInicio,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          label: AppStrings.navMais,
        ),
      ],
    );
  }
}
