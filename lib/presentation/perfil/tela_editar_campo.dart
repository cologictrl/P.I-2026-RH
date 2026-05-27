import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/utils/validadores.dart';
import 'package:rh_os/data/repositorios/ranking_repositorio_firestore.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';
import 'package:rh_os/presentation/widgets/botao_cta.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaEditarCampo extends ConsumerStatefulWidget {
  const TelaEditarCampo({
    super.key,
    required this.campo,
    required this.label,
    required this.valorAtual,
  });

  final String campo;
  final String label;
  final String valorAtual;

  @override
  ConsumerState<TelaEditarCampo> createState() => _TelaEditarCampoState();
}

class _TelaEditarCampoState extends ConsumerState<TelaEditarCampo> {
  late final TextEditingController _ctrl;
  bool _valido = true;
  bool _carregando = false;
  String? _erroTexto;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.valorAtual);
    _validar(widget.valorAtual);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _validar(String valor) {
    String? erro;
    switch (widget.campo) {
      case 'resumo':
        erro = Validadores.obrigatorio(valor);
        break;
      case 'email':
        erro = Validadores.email(valor);
        break;
      case 'cpf':
        erro = Validadores.cpf(valor);
        break;
      case 'telefone':
        erro = Validadores.telefone(valor);
        break;
      case 'cep':
        erro = Validadores.cep(valor);
        break;
      default:
        erro = null;
    }
    setState(() {
      _erroTexto = erro;
      _valido = erro == null;
    });
  }

  String _mapCampo(String campo) {
    switch (campo) {
      case 'nome_completo':
      case 'nome_preferencia':
        return 'nome';
      case 'rua':
        return 'logradouro';
      default:
        return campo;
    }
  }

  String _normalizarValor(String campo, String valor) {
    if (campo == 'telefone') {
      return Validadores.normalizarTelefone(valor) ?? '';
    }
    if (campo == 'cep') {
      return Validadores.normalizarCep(valor) ?? '';
    }
    return valor;
  }

  Future<void> _salvar() async {
    if (!_valido) return;
    setState(() => _carregando = true);

    final prefs = await SharedPreferences.getInstance();
    final campo = _mapCampo(widget.campo);
    final valor = _normalizarValor(campo, _ctrl.text.trim());
    final repo = getIt<ICandidatoRepositorio>();
    final uid = prefs.getString('usuario_uid');
    var candidato = uid != null ? await repo.buscarPorUsuarioUid(uid) : null;
    if (candidato == null) {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email != null && email.trim().isNotEmpty) {
        candidato = await repo.buscarPorEmail(email.trim());
      }
    }
    if (candidato?.idStr != null) {
      await repo.atualizarCampoStr(candidato!.idStr!, campo, valor);
      await getIt<RankingRepositorioFirestore>()
          .apagarPorCandidato(candidato.idStr!);
    }

    if (!mounted) return;
    setState(() => _carregando = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(AppStrings.campoSalvo),
        backgroundColor: AppCores.primaria));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isResumo = widget.campo == 'resumo';
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: RhosAppBarInterna(
        icone: Icons.edit_outlined,
        titulo: 'Editar ${widget.label}',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _validar,
              maxLines: isResumo ? 5 : 1,
              keyboardType:
                  isResumo ? TextInputType.multiline : TextInputType.text,
              decoration: InputDecoration(
                labelText: widget.label,
                errorText: _erroTexto,
              ),
            ),
            const SizedBox(height: 32),
            BotaoCta(
              label: AppStrings.salvar,
              carregando: _carregando,
              aoPresionar: _valido ? _salvar : null,
            ),
          ],
        ),
      ),
    );
  }
}
