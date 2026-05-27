import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/domain/repositorios/i_usuario_repositorio.dart';
import 'package:rh_os/domain/entidades/usuario.dart';
import 'package:rh_os/presentation/widgets/avatar_iniciais.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';

class TelaGestaoUsuarios extends ConsumerStatefulWidget {
  const TelaGestaoUsuarios({super.key});

  @override
  ConsumerState<TelaGestaoUsuarios> createState() =>
      _TelaGestaoUsuariosState();
}

class _TelaGestaoUsuariosState extends ConsumerState<TelaGestaoUsuarios> {
  List<Usuario> _usuarios = [];
  bool _carregando = true;
  // E-mail do usuário logado — obtido via FirebaseAuth para o guard de auto-desativação.
  String? _emailLogado;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    // Usa FirebaseAuth para identificar o admin logado sem depender de chave legada.
    _emailLogado = fb.FirebaseAuth.instance.currentUser?.email;
    final lista = await getIt<IUsuarioRepositorio>().listarTodos();
    if (!mounted) return;
    setState(() { _usuarios = lista; _carregando = false; });
  }

  Future<void> _toggleAtivo(Usuario u) async {
    // Impede que o admin desative a própria conta comparando por e-mail.
    if (u.email == _emailLogado) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(AppStrings.naoDesativarSi),
              backgroundColor: Colors.red));
      return;
    }
    await getIt<IUsuarioRepositorio>().atualizarAtivo(u.id!, !u.ativo);
    _carregar();
  }

  Future<void> _abrirFormulario({Usuario? usuario}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioUsuario(
        usuario: usuario,
        aoSalvar: _carregar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: const RhosAppBarInterna(
        icone: Icons.manage_accounts,
        titulo: AppStrings.tituloAdmin,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppCores.cta,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.person_add_outlined, color: AppCores.textoClaro),
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppCores.primaria))
          : _usuarios.isEmpty
              ? const Center(
                  child: Text(AppStrings.nenhumUsuario,
                      style: TextStyle(color: AppCores.textoSecundario)))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    itemCount: _usuarios.length,
                    itemBuilder: (_, i) {
                      final u = _usuarios[i];
                      return ListTile(
                        leading: AvatarIniciais(nome: u.nome, radius: 22),
                        title: Text(u.nome),
                        subtitle: Text(
                          '${u.email}  ·  ${u.perfil}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: u.ativo,
                              activeThumbColor: AppCores.primaria,
                              onChanged: u.id != null
                                  ? (_) => _toggleAtivo(u)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppCores.primaria, size: 20),
                              onPressed: () => _abrirFormulario(usuario: u),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _FormularioUsuario extends ConsumerStatefulWidget {
  const _FormularioUsuario({this.usuario, required this.aoSalvar});

  final Usuario? usuario;
  final VoidCallback aoSalvar;

  @override
  ConsumerState<_FormularioUsuario> createState() =>
      _FormularioUsuarioState();
}

class _FormularioUsuarioState extends ConsumerState<_FormularioUsuario> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _senhaCtrl;
  String _perfil = 'colaborador';
  bool _salvando = false;

  static const _perfis = ['colaborador', 'rh', 'admin'];

  @override
  void initState() {
    super.initState();
    _nomeCtrl =
        TextEditingController(text: widget.usuario?.nome ?? '');
    _emailCtrl =
        TextEditingController(text: widget.usuario?.email ?? '');
    _senhaCtrl = TextEditingController();
    _perfil = widget.usuario?.perfil ?? 'colaborador';
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final agora = DateTime.now().toIso8601String();
    final isNovo = widget.usuario == null;

    if (isNovo) {
      final u = Usuario(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        senhaHash: _senhaCtrl.text.trim(),
        perfil: _perfil,
        criadoEm: agora,
      );
      await getIt<IUsuarioRepositorio>().salvar(u);
    } else {
      final u = widget.usuario!.copyWith(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        senhaHash: _senhaCtrl.text.trim().isNotEmpty
            ? _senhaCtrl.text.trim()
            : widget.usuario!.senhaHash,
        perfil: _perfil,
      );
      await getIt<IUsuarioRepositorio>().atualizar(u);
    }

    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(
            content: Text(AppStrings.usuarioSalvo),
            backgroundColor: AppCores.primaria));
    Navigator.of(context).pop();
    widget.aoSalvar();
  }

  @override
  Widget build(BuildContext context) {
    final isNovo = widget.usuario == null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNovo ? AppStrings.novoUsuario : 'Editar usuário',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.erroCampoObrig
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.erroCampoObrig
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _senhaCtrl,
              decoration: InputDecoration(
                  labelText:
                      isNovo ? 'Senha' : 'Nova senha (deixe vazio p/ manter)'),
              obscureText: true,
              validator: isNovo
                  ? (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.erroCampoObrig
                      : null
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _perfil,
              decoration: const InputDecoration(labelText: 'Perfil'),
              items: _perfis
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) { if (v != null) setState(() => _perfil = v); },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppCores.cta,
                    foregroundColor: AppCores.textoClaro),
                onPressed: _salvando ? null : _salvar,
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text(AppStrings.salvar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
