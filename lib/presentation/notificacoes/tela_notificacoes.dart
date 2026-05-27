import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/domain/entidades/notificacao.dart';
import 'package:rh_os/domain/repositorios/i_notificacao_repositorio.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaNotificacoes extends ConsumerStatefulWidget {
  const TelaNotificacoes({super.key});

  @override
  ConsumerState<TelaNotificacoes> createState() => _TelaNotificacoesState();
}

class _TelaNotificacoesState extends ConsumerState<TelaNotificacoes> {
  final _dao = getIt<INotificacaoRepositorio>();
  List<Notificacao> _notificacoes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('usuario_uid');
    if (uid == null) {
      if (mounted) setState(() => _carregando = false);
      return;
    }
    // listarTodas: interface legada usa int; notificações Firestore
    // são exibidas via StreamBuilder no AppBar. Esta tela mostra histórico.
    final lista = await _dao.listarTodas();
    if (mounted) setState(() { _notificacoes = lista; _carregando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: const RhosAppBarInterna(
        icone: Icons.notifications_outlined,
        titulo: AppStrings.menuNotificacoes,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppCores.primaria))
          : _notificacoes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: AppCores.textoSecundario),
                      SizedBox(height: 12),
                      Text('Nenhuma notificação', style: TextStyle(color: AppCores.textoSecundario)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _notificacoes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = _notificacoes[i];
                    return ListTile(
                      leading: Icon(
                        n.lida ? Icons.notifications_none : Icons.notifications,
                        color: n.lida ? AppCores.textoSecundario : AppCores.primaria,
                      ),
                      title: Text(n.titulo, style: TextStyle(
                        fontWeight: n.lida ? FontWeight.normal : FontWeight.bold,
                      )),
                      subtitle: Text(n.mensagem, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () async {
                        await _dao.marcarComoLida(n.id!);
                        _carregar();
                      },
                    );
                  },
                ),
    );
  }
}