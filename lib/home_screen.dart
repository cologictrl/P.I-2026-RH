import 'package:flutter/material.dart';
import 'package:rhos/login_screen.dart';
import 'package:rhos/palette.dart';
import 'package:rhos/services/mock_auth_service.dart';

class HomeScreen extends StatelessWidget {
  final String nomeCompletoUsuario;

  const HomeScreen({super.key, required this.nomeCompletoUsuario});

  String _obterIniciais(String nomeCompleto) {
    final partes = nomeCompleto
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (partes.isEmpty) {
      return '--';
    }
    if (partes.length == 1) {
      final primeiraParte = partes.first;
      if (primeiraParte.length == 1) {
        return primeiraParte.toUpperCase();
      }
      return primeiraParte.substring(0, 2).toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  void _sair(BuildContext context) {
    ServicoAuthMock.instancia.sair();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final iniciais = _obterIniciais(nomeCompletoUsuario);

    return Scaffold(
      backgroundColor: Palette.backgroundColor3, // Cor do fundo
      // Barra Superior
      appBar: AppBar(
        backgroundColor: Palette.backgroundColor1, // Cor da barra
        elevation: 0,
        title: Row(
          children: [
            // Quadrado com as inicias "EP"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Palette.backgroundColor2, // Cor fundo nome
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                iniciais,
                style: TextStyle(
                  color: Palette.backgroundColor1, // Cor do nome
                  fontWeight: FontWeight.w900, // Formatação nome
                  fontSize: 20, // Tamanho do nome
                ),
              ),
            ),
            const SizedBox(width: 15),
            // Texto Olá Elias Pires
            Text(
              'Olá $nomeCompletoUsuario',
              style: const TextStyle(
                color: Palette.textColor1, // Cor do nome
                fontSize: 18, // Tamanho da fonte
                fontWeight: FontWeight.w600, // Formatação da fonte
              ),
            ),
          ],
        ),
        actions: [
          // Ícone de notificação
          IconButton(
            icon: const Icon(Icons.notifications, color: Palette.textColor1),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Palette.textColor1),
            onPressed: () => _sair(context),
          ),
        ],
      ),
      // Corpo tela body
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centraliza tudo no meio
          children: [
            const Text(
              'RH-OS',
              style: TextStyle(
                fontSize: 45, // Tamanho do texto
                fontWeight: FontWeight.w900, // Formatação texto
                color: Palette.textColor2, // Cor do texto
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Sistema de Gestão de Recursos Humanos',
              style: TextStyle(
                fontSize: 16, // Tamanho do texto
                fontWeight: FontWeight.w600, // Formatação do texto
                color: Palette.textColor2, // Cor do texto
              ),
            ),
            const SizedBox(height: 30),

            // Logo
            Image.asset(
              'assets/images/logo_rhos.png',
              height: 280, // Tamanho logo
            ),
            const SizedBox(height: 30),
            const Text(
              'Gestão inteligente para sua empresa',
              style: TextStyle(
                fontSize: 16, // Tamanho do texto
                fontWeight: FontWeight.w600, // Formatação do texto
                color: Palette.textColor2, // Cor do texto
              ),
            ),
          ],
        ),
      ),
      // Barra inferior (Navegação)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Palette.backgroundColor1,
        selectedItemColor: Palette.backgroundColor4, // Cor selecionado
        unselectedItemColor: Palette.backgroundColor2, // Cor não selecionado
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Mais'),
        ],
      ),
    );
  }
}
