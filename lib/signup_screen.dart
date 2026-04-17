import 'package:flutter/material.dart';
import 'package:rhos/palette.dart';
import 'package:rhos/services/mock_auth_service.dart';
import 'package:rhos/widgets/custom_button.dart';
import 'package:rhos/widgets/login_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _chaveFormulario = GlobalKey<FormState>();
  final TextEditingController _controladorNomeCompleto =
      TextEditingController();
  final TextEditingController _controladorUsuario = TextEditingController();
  final TextEditingController _controladorEmail = TextEditingController();
  final TextEditingController _controladorSenha = TextEditingController();
  final TextEditingController _controladorConfirmarSenha =
      TextEditingController();

  bool _enviando = false;

  @override
  void dispose() {
    _controladorNomeCompleto.dispose();
    _controladorUsuario.dispose();
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _controladorConfirmarSenha.dispose();
    super.dispose();
  }

  String? _validarObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Preencha este campo.';
    }
    return null;
  }

  Future<void> _cadastrar() async {
    if (!_chaveFormulario.currentState!.validate()) {
      return;
    }

    final senha = _controladorSenha.text.trim();
    final confirmarSenha = _controladorConfirmarSenha.text.trim();

    if (senha.length < 6) {
      _mostrarMensagem('A senha deve conter ao menos 6 caracteres.');
      return;
    }

    if (senha != confirmarSenha) {
      _mostrarMensagem('As senhas não coincidem.');
      return;
    }

    setState(() {
      _enviando = true;
    });

    final resultado = await ServicoAuthMock.instancia.cadastrar(
      nomeCompleto: _controladorNomeCompleto.text.trim(),
      usuario: _controladorUsuario.text.trim(),
      email: _controladorEmail.text.trim(),
      senha: senha,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _enviando = false;
    });

    if (!resultado.sucesso) {
      _mostrarMensagem(resultado.mensagem);
      return;
    }

    Navigator.pop(context, {
      'identificador': resultado.usuario!.usuario,
      'senha': senha,
      'mensagem': resultado.mensagem,
    });
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
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _chaveFormulario,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Criar Conta',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      color: Palette.textColor2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cadastre seus dados para acessar o RH-OS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Palette.textColor2,
                    ),
                  ),
                  const SizedBox(height: 30),
                  LoginField(
                    textoDica: 'Nome completo',
                    icone: Icons.badge,
                    controlador: _controladorNomeCompleto,
                    validador: (valor) {
                      final erroObrigatorio = _validarObrigatorio(valor);
                      if (erroObrigatorio != null) {
                        return erroObrigatorio;
                      }
                      if (valor!.trim().length < 3) {
                        return 'Digite pelo menos 3 caracteres.';
                      }
                      return null;
                    },
                    acaoTeclado: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  LoginField(
                    textoDica: 'Usuário',
                    icone: Icons.person,
                    controlador: _controladorUsuario,
                    validador: (valor) {
                      final erroObrigatorio = _validarObrigatorio(valor);
                      if (erroObrigatorio != null) {
                        return erroObrigatorio;
                      }
                      if (valor!.trim().length < 3) {
                        return 'Usuário muito curto.';
                      }
                      return null;
                    },
                    acaoTeclado: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  LoginField(
                    textoDica: 'E-mail',
                    icone: Icons.email,
                    controlador: _controladorEmail,
                    tipoTeclado: TextInputType.emailAddress,
                    validador: (valor) {
                      final erroObrigatorio = _validarObrigatorio(valor);
                      if (erroObrigatorio != null) {
                        return erroObrigatorio;
                      }
                      final email = valor!.trim();
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Digite um e-mail válido.';
                      }
                      return null;
                    },
                    acaoTeclado: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  LoginField(
                    textoDica: 'Senha',
                    icone: Icons.lock,
                    campoSenha: true,
                    controlador: _controladorSenha,
                    validador: _validarObrigatorio,
                    acaoTeclado: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  LoginField(
                    textoDica: 'Confirmar senha',
                    icone: Icons.lock_outline,
                    campoSenha: true,
                    controlador: _controladorConfirmarSenha,
                    validador: _validarObrigatorio,
                    acaoTeclado: TextInputAction.done,
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    texto: _enviando ? 'Cadastrando...' : 'Cadastrar',
                    cor: Palette.backgroundColor4,
                    aoPressionar: _enviando ? null : _cadastrar,
                    largura: 350,
                    altura: 62,
                    tamanhoFonte: 24,
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _enviando ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Voltar para login',
                      style: TextStyle(
                        color: Palette.backgroundColor1,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
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
