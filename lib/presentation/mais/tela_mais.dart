import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rh_os/core/constantes/app_rotas.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/tema/app_estilos.dart';
import 'package:rh_os/domain/casos_de_uso/autenticar_usuario.dart';
import 'package:rh_os/presentation/widgets/avatar_iniciais.dart';
import 'package:rh_os/presentation/widgets/rhos_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaMais extends ConsumerStatefulWidget {
  const TelaMais({super.key});

  @override
  ConsumerState<TelaMais> createState() => _TelaMaisState();
}

class _TelaMaisState extends ConsumerState<TelaMais> {
  String _nome = 'Usuário';
  String _email = '';
  String _perfil = '';

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('usuario_uid') ?? '';
    if (uid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nome = (data['nome'] as String? ?? '').isNotEmpty
              ? data['nome'] as String
              : 'Usuário';
          _email = data['email'] as String? ?? '';
          _perfil = data['perfil'] as String? ?? '';
        });
      }
    } catch (e) {
      debugPrint('[TelaMais] Erro ao carregar usuário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final isAdmin = _perfil == 'admin';

    final isAdminOuRecrutador = _perfil == 'admin' || _perfil == 'recrutador';

    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppCores.primaria,
            padding:
                EdgeInsets.only(top: top + 24, bottom: 24, left: 16, right: 16),
            child: Column(
              children: [
                AvatarIniciais(nome: _nome, radius: 32),
                const SizedBox(height: 8),
                Text(
                  _nome,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppCores.textoClaro,
                  ),
                ),
                if (_email.isNotEmpty)
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppCores.textoClaro.withAlpha(204),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Item(
                    icone: Icons.home_outlined,
                    label: AppStrings.navInicio,
                    aoTap: () => context.go(AppRotas.home)),
                const Divider(height: 1),
                _Item(
                    icone: Icons.notifications_outlined,
                    label: AppStrings.menuNotificacoes,
                    aoTap: () => context.push(AppRotas.notificacoes)),
                const Divider(height: 1),
                _Item(
                    icone: Icons.person_outlined,
                    label: AppStrings.menuPerfil,
                    aoTap: () => context.push(AppRotas.perfil)),
                const Divider(height: 1),
                _Item(
                    icone: Icons.description_outlined,
                    label: AppStrings.menuCurriculos,
                    aoTap: () => context.push(AppRotas.curriculos)),
                const Divider(height: 1),
                _Item(
                    icone: Icons.work_outline,
                    label: AppStrings.menuVagas,
                    aoTap: () => context.push(AppRotas.vagas)),
                const Divider(height: 1),
                // A5 — Entrevistas: visível para admin e recrutador
                if (isAdminOuRecrutador) ...[
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined,
                        color: AppCores.textoSecundario),
                    title:
                        const Text('Entrevistas', style: AppEstilos.valorCampo),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppCores.textoSecundario),
                    onTap: () => context.push(AppRotas.entrevistas),
                  ),
                  const Divider(height: 1),
                ],
                _Item(
                    icone: Icons.upload_file,
                    label: AppStrings.menuUpload,
                    aoTap: () => context.push(AppRotas.upload)),
                if (isAdmin) ...[
                  const Divider(height: 1),
                  _Item(
                      icone: Icons.manage_accounts,
                      label: AppStrings.menuGestaoUsuarios,
                      aoTap: () => context.push(AppRotas.admin)),
                ],
                const Divider(height: 1),
                _Item(
                  icone: Icons.logout,
                  label: 'Sair',
                  aoTap: () async {
                    await getIt<AutenticarUsuario>().sair();
                    if (context.mounted) context.go(AppRotas.login);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: RhosBottomNav(
        indiceAtual: 1,
        aoMudar: (i) {
          if (i == 0) context.go(AppRotas.home);
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icone, required this.label, required this.aoTap});
  final IconData icone;
  final String label;
  final VoidCallback aoTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: AppCores.textoSecundario),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing:
          const Icon(Icons.chevron_right, color: AppCores.textoSecundario),
      onTap: aoTap,
    );
  }
}
