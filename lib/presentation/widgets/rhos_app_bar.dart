// ============================================================
// rhos_app_bar.dart
// Responsabilidade: AppBar customizado nas variantes Home e Interna
// Camada: presentation
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/tema/app_estilos.dart';
import 'package:rh_os/presentation/widgets/avatar_iniciais.dart';

class RhosAppBarHome extends StatelessWidget implements PreferredSizeWidget {
  // Construtor da AppBar da tela inicial
  const RhosAppBarHome({
    super.key,
    required this.nomeUsuario,
    this.onNotificacoes,
    this.uid,
  });

  final String nomeUsuario;
  final VoidCallback? onNotificacoes;

  /// A4 — uid do usuario logado para exibir badge de nao lidas.
  final String? uid;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Monta a barra superior com saudacao e notificacoes
    return AppBar(
      backgroundColor: AppCores.primaria,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          AvatarIniciais(nome: nomeUsuario, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Olá, ${_primeiroNome(nomeUsuario)}',
              style: AppEstilos.tituloAppBar,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // A4 — badge de notificacoes nao lidas quando uid disponivel
        if (uid != null && uid!.isNotEmpty)
          _BadgeSino(uid: uid!, onTap: onNotificacoes)
        else
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppCores.textoClaro),
            onPressed: onNotificacoes,
          ),
      ],
    );
  }

  String _primeiroNome(String nome) {
    // Extrai apenas o primeiro nome para a saudacao
    final partes = nome.trim().split(' ');
    return partes.isNotEmpty ? partes[0] : nome;
  }
}

/// Badge vermelho sobre o icone de sino quando ha notificacoes nao lidas.
class _BadgeSino extends StatelessWidget {
  const _BadgeSino({required this.uid, this.onTap});

  final String uid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('notificacoes')
        .where('usuario_uid', isEqualTo: uid)
        .where('lida', isEqualTo: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return IconButton(
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined,
                  color: AppCores.textoClaro),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: CircleAvatar(
                    radius: 7,
                    backgroundColor: Colors.red,
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class RhosAppBarInterna extends StatelessWidget implements PreferredSizeWidget {
  // Construtor da AppBar das telas internas
  const RhosAppBarInterna({
    super.key,
    required this.titulo,
    required this.icone,
    this.actions,
  });

  final String titulo;
  final IconData icone;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Monta a barra superior com botao de voltar
    return AppBar(
      backgroundColor: AppCores.primaria,
      leading: BackButton(
        color: AppCores.textoClaro,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: AppCores.textoClaro, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              titulo,
              style: AppEstilos.tituloAppBar,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: actions,
    );
  }
}
