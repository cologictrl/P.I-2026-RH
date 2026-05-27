// Tela de autenticacao do usuario
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rh_os/core/constantes/app_rotas.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/tema/app_estilos.dart';
import 'package:rh_os/domain/casos_de_uso/autenticar_usuario.dart';
import 'package:rh_os/presentation/widgets/botao_cta.dart';

class TelaLogin extends ConsumerStatefulWidget {
  // Construtor padrao da tela
  const TelaLogin({super.key});

  @override
  ConsumerState<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends ConsumerState<TelaLogin> {
  // Controla o formulario e os campos de entrada
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _carregando = false;
  bool _ocultarSenha = true;

  @override
  void dispose() {
    // Libera os controladores ao sair da tela
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    // Valida os campos antes de prosseguir
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    // Executa a autenticacao via caso de uso
    final usuario = await getIt<AutenticarUsuario>()
        .executar(_emailCtrl.text, _senhaCtrl.text);

    if (!mounted) return;
    setState(() => _carregando = false);

    if (usuario != null) {
      // Navega para a tela principal quando o login der certo
      context.go(AppRotas.home);
    } else {
      // Exibe feedback quando a autenticacao falha
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(AppStrings.erroLoginInvalido),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcula altura para construir o cabecalho proporcional
    final altura = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppCores.fundoCard,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: altura * 0.40,
            decoration: const BoxDecoration(
              color: AppCores.primaria,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings_suggest,
                    size: 80, color: AppCores.textoClaro),
                SizedBox(height: 12),
                Text(AppStrings.nomeApp, style: AppEstilos.tituloPrincipal),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.subtituloApp,
                    style: TextStyle(fontSize: 14, color: AppCores.textoClaro),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      AppStrings.boasVindas,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppCores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.subtituloLogin,
                      style: TextStyle(
                          fontSize: 14, color: AppCores.textoSecundario),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: AppStrings.labelUsuario,
                        suffixIcon: Icon(Icons.person_outline,
                            color: AppCores.textoSecundario),
                      ),
                      // Valida e-mail obrigatorio
                      validator: (v) => v == null || v.trim().isEmpty
                          ? AppStrings.erroCampoObrig
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaCtrl,
                      obscureText: _ocultarSenha,
                      decoration: InputDecoration(
                        hintText: AppStrings.labelSenha,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarSenha
                                ? Icons.lock_outline
                                : Icons.visibility_off,
                            color: AppCores.textoSecundario,
                          ),
                          onPressed: () =>
                              setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                      // Valida senha obrigatoria
                      validator: (v) => v == null || v.trim().isEmpty
                          ? AppStrings.erroCampoObrig
                          : null,
                    ),
                    const SizedBox(height: 32),
                    BotaoCta(
                      label: AppStrings.botaoEntrar,
                      carregando: _carregando,
                      aoPresionar: _entrar,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
