import 'package:flutter/material.dart';
import 'package:rhos/home_screen.dart';
import 'package:rhos/signup_screen.dart';
import 'package:rhos/services/mock_auth_service.dart';
import 'package:rhos/widgets/custom_button.dart';
import 'package:rhos/widgets/login_field.dart';
import 'package:rhos/palette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _chaveFormulario = GlobalKey<FormState>();
  final TextEditingController _controladorIdentificador =
      TextEditingController();
  final TextEditingController _controladorSenha = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _controladorIdentificador.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  String? _validarObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Preencha este campo.';
    }
    return null;
  }

  Future<void> _fazerLogin() async {
    if (!_chaveFormulario.currentState!.validate()) {
      return;
    }

    setState(() {
      _enviando = true;
    });

    final resultado = await ServicoAuthMock.instancia.login(
      identificador: _controladorIdentificador.text.trim(),
      senha: _controladorSenha.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _enviando = false;
    });

    if (!resultado.sucesso || resultado.usuario == null) {
      _mostrarMensagem(resultado.mensagem);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HomeScreen(nomeCompletoUsuario: resultado.usuario!.nomeCompleto),
      ),
    );
  }

  Future<void> _irParaCadastro() async {
    final retorno = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );

    if (!mounted || retorno == null) {
      return;
    }

    final identificador = retorno['identificador'];
    final senha = retorno['senha'];
    final mensagem = retorno['mensagem'];

    if (identificador is String) {
      _controladorIdentificador.text = identificador;
    }
    if (senha is String) {
      _controladorSenha.text = senha;
    }
    if (mensagem is String && mensagem.isNotEmpty) {
      _mostrarMensagem('$mensagem Faça login para continuar.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _chaveFormulario,
              child: Column(
                children: [
                  Image.asset('assets/images/rhos.jpg'),
                  const SizedBox(height: 30),
                  const Text(
                    'Boas - Vindas',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w400,
                      color: Palette.textColor2,
                    ),
                  ),
                  const Text(
                    'Entre com seu usuário e senha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Palette.textColor2,
                    ),
                  ),
                  const SizedBox(height: 50),
                  LoginField(
                    textoDica: 'Usuário ou e-mail',
                    icone: Icons.person,
                    controlador: _controladorIdentificador,
                    validador: _validarObrigatorio,
                    acaoTeclado: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  LoginField(
                    textoDica: 'Senha',
                    campoSenha: true,
                    icone: Icons.lock,
                    controlador: _controladorSenha,
                    validador: _validarObrigatorio,
                    acaoTeclado: TextInputAction.done,
                  ),
                  const SizedBox(height: 50),
                  CustomButton(
                    texto: _enviando ? 'Entrando...' : 'Entrar',
                    cor: Palette.backgroundColor4,
                    aoPressionar: _enviando ? null : _fazerLogin,
                    largura: 360,
                    altura: 70,
                    tamanhoFonte: 30,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _enviando ? null : _irParaCadastro,
                    child: const Text(
                      'Nao tem conta? Cadastre-se',
                      style: TextStyle(
                        color: Palette.backgroundColor1,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
