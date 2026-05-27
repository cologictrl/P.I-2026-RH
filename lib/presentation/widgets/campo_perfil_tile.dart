/* ============================================================
 * campo_perfil_tile.dart
 * Responsabilidade: ListTile para exibição de campos do perfil
 * Camada: presentation
 * ============================================================ */

import 'package:flutter/material.dart';
import 'package:rh_os/core/tema/app_cores.dart';

class CampoPerfilTile extends StatelessWidget {
  const CampoPerfilTile({
    super.key,
    required this.icone,
    required this.valor,
    required this.label,
    this.editavel = true,
    this.aoTap,
  });

  final IconData icone;
  final String valor;
  final String label;
  final bool editavel;
  final VoidCallback? aoTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icone, color: AppCores.textoSecundario, size: 22),
      title: Text(
        valor.isNotEmpty ? valor : '—',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCores.textoPrincipal,
            ),
      ),
      subtitle: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppCores.textoSecundario,
            ),
      ),
      trailing: editavel
          ? const Icon(Icons.chevron_right, color: AppCores.textoSecundario)
          : null,
      onTap: editavel ? aoTap : null,
    );
  }
}