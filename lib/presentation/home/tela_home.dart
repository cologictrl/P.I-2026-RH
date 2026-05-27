// Tela inicial da aplicacao
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rh_os/core/constantes/app_rotas.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';
import 'package:rh_os/presentation/widgets/rhos_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaHome extends ConsumerStatefulWidget {
  // Construtor padrao da tela
  const TelaHome({super.key});

  @override
  ConsumerState<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends ConsumerState<TelaHome> {
  // Nome exibido no cabecalho
  String _nomeUsuario = 'Usuário';
  // A4 — uid para badge de notificacoes
  String _uid = '';

  @override
  void initState() {
    super.initState();
    // Carrega os dados do usuario ao abrir a tela
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('usuario_uid') ?? '';

    // Tenta displayName do FirebaseAuth primeiro
    final firebaseUser = FirebaseAuth.instance.currentUser;
    String nome = firebaseUser?.displayName?.trim() ?? '';

    // Fallback: busca nome na colecao 'usuarios' do Firestore
    if (nome.isEmpty && uid.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();
        if (doc.exists) {
          nome = (doc.data()?['nome'] as String? ?? '').trim();
        }
      } catch (_) {}
    }

    // Fallback: parte do e-mail antes do @
    if (nome.isEmpty) {
      final email = firebaseUser?.email ?? '';
      nome = email.contains('@') ? email.split('@').first : email;
    }

    if (mounted) {
      setState(() {
        _nomeUsuario = nome.isNotEmpty ? nome : 'Usuário';
        _uid = uid; // A4 — armazena uid para badge de notificacoes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Monta a tela principal com menu inferior
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: RhosAppBarHome(
        nomeUsuario: _nomeUsuario,
        uid: _uid.isNotEmpty ? _uid : null,
        onNotificacoes: () => context.push(AppRotas.notificacoes),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_suggest, size: 120, color: AppCores.primaria),
            SizedBox(height: 16),
            Text(
              AppStrings.nomeApp,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppCores.textoSecundario,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppStrings.subtituloApp,
              style: TextStyle(fontSize: 14, color: AppCores.textoSecundario),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              AppStrings.tagline,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppCores.textoPrincipal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: RhosBottomNav(
        indiceAtual: 0,
        aoMudar: (i) {
          // Navega para a area de mais opcoes quando necessario
          if (i == 1) context.go(AppRotas.mais);
        },
      ),
    );
  }
}
