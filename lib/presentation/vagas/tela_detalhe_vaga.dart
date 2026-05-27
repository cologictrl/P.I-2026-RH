import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rh_os/core/constantes/app_rotas.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/constantes/ranking_config.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/data/servicos/auditoria_service.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/data/repositorios/entrevista_repositorio_firestore.dart';
import 'package:rh_os/data/repositorios/ranking_repositorio_firestore.dart';
import 'package:rh_os/data/servicos/ranking_service.dart';
import 'package:rh_os/domain/casos_de_uso/candidatos/listar_candidatos.dart';
import 'package:rh_os/domain/casos_de_uso/ranquear_candidatos.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/entidades/candidatura.dart';
import 'package:rh_os/domain/entidades/entrevista.dart';
import 'package:rh_os/domain/entidades/vaga.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';
import 'package:rh_os/domain/repositorios/i_candidatura_repositorio.dart';
import 'package:rh_os/domain/repositorios/i_vaga_repositorio.dart';
import 'package:rh_os/presentation/vagas/tela_criar_vaga.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';

class TelaDetalheVaga extends ConsumerStatefulWidget {
  /// vagaIdStr é o identificador principal no Firestore (idStr).
  const TelaDetalheVaga({super.key, required this.vagaIdStr});

  final String vagaIdStr;

  @override
  ConsumerState<TelaDetalheVaga> createState() => _TelaDetalheVagaState();
}

class _TelaDetalheVagaState extends ConsumerState<TelaDetalheVaga>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _carregando = true;
  Vaga? _vaga;
  List<Candidatura> _candidaturas = [];

  /// Mapa keyed por candidatoIdStr (String).
  Map<String, Candidato?> _candidatos = {};

  // ── Estado de ranking ──────────────────────────────────────────────────────
  /// Resultados do ranking: candidatoIdStr → {score, justificativa, ...}
  final Map<String, Map<String, dynamic>> _rankings = {};
  bool _calculandoRanking = false;
  bool _usouScoreLocal = false;
  String? _erroRanking;
  int _falhasRanking = 0;

  // ── Filtros R6 ─────────────────────────────────────────────────────────────
  double _scoreMinimo = 0;
  String _filtroStatus = 'Todos';

  static const _opcoesStatus = ['Todos', 'Em análise', 'Aprovado', 'Reprovado'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Carregamento inicial ───────────────────────────────────────────────────

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final vagaRepo = getIt<IVagaRepositorio>();
      final candRepo = getIt<ICandidaturaRepositorio>();
      final candidatoRepo = getIt<ICandidatoRepositorio>();

      final vaga = await vagaRepo.buscarPorIdStr(widget.vagaIdStr);
      final candidaturas = await candRepo.listarPorVagaStr(widget.vagaIdStr);
      final Map<String, Candidato?> mapa = {};
      for (final c in candidaturas) {
        final idStr = c.candidatoIdStr;
        if (idStr != null && idStr.isNotEmpty) {
          mapa[idStr] = await candidatoRepo.buscarPorIdStr(idStr);
        }
      }

      if (!mounted) return;
      setState(() {
        _vaga = vaga;
        _candidaturas = candidaturas;
        _candidatos = mapa;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('[TelaDetalheVaga] Erro ao carregar: $e');
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  // ── Ranking IA ─────────────────────────────────────────────────────────────

  Future<void> _calcularRanking() async {
    if (_vaga == null) return;
    if (_candidaturas.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nenhum candidato vinculado para ranquear.'),
        backgroundColor: AppCores.cta,
      ));
      return;
    }
    setState(() {
      _calculandoRanking = true;
      _usouScoreLocal = false;
      _erroRanking = null;
      _falhasRanking = 0;
    });

    final rankingService = getIt<RankingService>();
    final rankingRepo = getIt<RankingRepositorioFirestore>();
    final candidatoRepo = getIt<ICandidatoRepositorio>();
    final candRepo = getIt<ICandidaturaRepositorio>();
    final ranquear = getIt<RanquearCandidatos>();

    // Respeitar limite de lote
    final todos = _candidaturas.where((c) => c.candidatoIdStr != null).toList();
    if (todos.length > RankingConfig.maxCandidatosPorLote && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Limite de ${RankingConfig.maxCandidatosPorLote} candidatos por lote. '
          'Use os filtros e calcule novamente.',
        ),
        backgroundColor: AppCores.cta,
      ));
    }
    final lote = todos.take(RankingConfig.maxCandidatosPorLote).toList();

    bool usouLocal = false;
    int falhas = 0;

    Future<void> atualizarScoreCandidatura(
        String? candidaturaIdStr, double score) async {
      if (candidaturaIdStr == null || score <= 0) return;
      try {
        await candRepo.atualizarScoreStr(candidaturaIdStr, score);
      } catch (e, st) {
        falhas++;
        _registrarFalhaRanking(
          'atualizar_score',
          e,
          st,
          candidaturaIdStr: candidaturaIdStr,
        );
      }
    }

    for (final cand in lote) {
      final candidatoIdStr = cand.candidatoIdStr!;
      final candidaturaIdStr = cand.idStr;
      final candidato = _candidatos[candidatoIdStr];
      if (candidato == null) continue;

      try {
        // Verificar cache no Firestore
        final cache =
            await rankingRepo.buscar(widget.vagaIdStr, candidatoIdStr);
        if (cache != null) {
          if (mounted) setState(() => _rankings[candidatoIdStr] = cache);
          final score = _scoreDoRanking(cache);
          await atualizarScoreCandidatura(candidaturaIdStr, score);
          continue;
        }

        // Carregar listas estruturadas do candidato
        final habilidades =
            await candidatoRepo.listarHabilidadesStr(candidatoIdStr);
        final idiomas = await candidatoRepo.listarIdiomasStr(candidatoIdStr);
        final experiencias =
            await candidatoRepo.listarExperienciasStr(candidatoIdStr);
        final formacoes =
            await candidatoRepo.listarFormacoesStr(candidatoIdStr);

        // Chamar Gemini
        final resultado = await rankingService.calcularRanking(
          _vaga!,
          candidato,
          habilidades: habilidades,
          idiomas: idiomas,
          experiencias: experiencias,
          formacoes: formacoes,
        );

        if (resultado != null) {
          // Persistir no Firestore e atualizar UI
          await rankingRepo.salvar(widget.vagaIdStr, candidatoIdStr, resultado);
          if (mounted) setState(() => _rankings[candidatoIdStr] = resultado);
          final score = _scoreDoRanking(resultado);
          await atualizarScoreCandidatura(candidaturaIdStr, score);
        } else {
          // Fallback: score local sem IA
          usouLocal = true;
          final detalhado = ranquear.calcularDetalhado(
            candidato,
            _vaga!,
            habilidades: habilidades,
            idiomas: idiomas,
            experiencias: experiencias,
            formacoes: formacoes,
          );
          final dadosLocais = <String, dynamic>{
            ...detalhado.toMap(),
            'justificativa': 'Score calculado localmente (sem IA).',
            'pontos_fortes': <String>[],
            'pontos_fracos': <String>[],
          };
          await rankingRepo.salvar(
              widget.vagaIdStr, candidatoIdStr, dadosLocais);
          if (mounted) setState(() => _rankings[candidatoIdStr] = dadosLocais);
          await atualizarScoreCandidatura(
              candidaturaIdStr, detalhado.scoreTotal);
        }
      } catch (e, st) {
        falhas++;
        _registrarFalhaRanking(
          'calcular_ranking',
          e,
          st,
          candidatoIdStr: candidatoIdStr,
          candidaturaIdStr: candidaturaIdStr,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _calculandoRanking = false;
      _usouScoreLocal = usouLocal;
      _falhasRanking = falhas;
      _erroRanking = falhas > 0
          ? 'Ranking concluido com falhas em $falhas candidato(s).'
          : null;
    });

    if (falhas > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_erroRanking!),
        backgroundColor: AppCores.cta,
      ));
    }
  }

  Future<void> _registrarFalhaRanking(
    String etapa,
    Object erro,
    StackTrace st, {
    String? candidatoIdStr,
    String? candidaturaIdStr,
  }) async {
    debugPrint('[TelaDetalheVaga] Ranking falhou ($etapa): $erro');
    await FirebaseCrashlytics.instance.recordError(
      erro,
      st,
      reason: 'TelaDetalheVaga.$etapa',
      information: <Object>[
        'vagaIdStr=${widget.vagaIdStr}',
        if (candidatoIdStr != null) 'candidatoIdStr=$candidatoIdStr',
        if (candidaturaIdStr != null) 'candidaturaIdStr=$candidaturaIdStr',
      ],
    );
  }

  // ── Alteração de status ────────────────────────────────────────────────────

  Future<void> _alterarStatus(Candidatura c, String novoStatus) async {
    try {
      if (c.idStr != null) {
        await getIt<ICandidaturaRepositorio>()
            .atualizarStatusStr(c.idStr!, novoStatus);
      }
    } catch (e) {
      debugPrint('[TelaDetalheVaga] Erro ao alterar status: $e');
    }

    // Q3 — Auditoria: registra aprovação de candidato.
    if (novoStatus == 'aprovado') {
      final candidatoAprovado = _candidatos[c.candidatoIdStr ?? ''];
      final vagaTitulo = _vaga?.titulo ?? '';
      final uid = c.candidatoIdStr ?? '';
      getIt<AuditoriaService>().registrar(
        uid: uid,
        acao: 'aprovacao_candidato',
        detalhes: '${candidatoAprovado?.nome ?? uid} → $vagaTitulo',
      );
    }

    // A2 — ao aprovar, sugerir agendamento de entrevista
    if (novoStatus == 'aprovado' && mounted) {
      final candidato = _candidatos[c.candidatoIdStr ?? ''];
      if (candidato != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Candidato aprovado!'),
            content:
                const Text('Deseja agendar uma entrevista com este candidato?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Não agora'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppCores.cta),
                onPressed: () {
                  Navigator.pop(context);
                  _agendarEntrevista(candidato);
                },
                child: const Text('Agendar entrevista',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    }

    _carregar();
  }

  // ── Agendamento de entrevista (A2) ─────────────────────────────────────────

  Future<void> _agendarEntrevista(Candidato candidato) async {
    // 1. Selecionar data
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (data == null || !mounted) return;

    // 2. Selecionar hora
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (hora == null || !mounted) return;

    final dataHora =
        DateTime(data.year, data.month, data.day, hora.hour, hora.minute);

    // 3. Observações opcionais
    final obsCtrl = TextEditingController();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Observações (opcional)'),
        content: TextField(
          controller: obsCtrl,
          decoration: const InputDecoration(
              hintText: 'Ex: trazer portfólio, reunião remota...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppCores.cta),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    final obsTexto = obsCtrl.text.trim();
    obsCtrl.dispose();

    if (confirmou != true || !mounted) return;

    // 4. Salvar entrevista no Firestore
    final entrevistaRepo = getIt<EntrevistaRepositorioFirestore>();
    final entrevista = Entrevista(
      vagaIdStr: widget.vagaIdStr,
      candidatoIdStr: candidato.idStr ?? '',
      dataHora: dataHora.toIso8601String(),
      status: 'pendente',
      observacoes: obsTexto.isEmpty ? null : obsTexto,
      vagaTitulo: _vaga?.titulo,
      candidatoNome: candidato.nome,
    );
    final entrevistaIdStr = await entrevistaRepo.salvar(entrevista);

    // 5. A4 — criar notificação no Firestore para o candidato
    if (entrevistaIdStr != null) {
      try {
        await FirebaseFirestore.instance.collection('notificacoes').add({
          'titulo': 'Entrevista agendada',
          'mensagem': 'Você tem uma entrevista para ${_vaga?.titulo ?? ''} em '
              '${DateFormat('dd/MM/yyyy HH:mm').format(dataHora)}',
          'usuario_uid': candidato.usuarioUid ?? candidato.idStr,
          'lida': false,
          'criado_em': DateTime.now().toIso8601String(),
          'tipo': 'entrevista',
          'referencia_id': entrevistaIdStr,
        });
      } catch (e) {
        debugPrint('[TelaDetalheVaga] Erro ao criar notificação: $e');
      }
    }

    // 6. Feedback ao recrutador
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Entrevista agendada com sucesso'),
      backgroundColor: AppCores.primaria,
    ));
  }

  // ── Vincular candidato ─────────────────────────────────────────────────────

  Future<void> _vincularCandidato() async {
    final todos = await getIt<ListarCandidatos>().executar();
    final vinculados =
        _candidatos.values.whereType<Candidato>().map((c) => c.idStr).toSet();
    final disponiveis =
        todos.where((c) => !vinculados.contains(c.idStr)).toList();

    if (!mounted) return;
    final selecionado = await showDialog<Candidato>(
      context: context,
      builder: (_) => _DialogoBuscarCandidato(candidatos: disponiveis),
    );
    if (selecionado == null || !mounted) return;

    try {
      final agora = DateTime.now().toIso8601String();
      final candidatura = Candidatura(
        candidatoId: 0,
        vagaId: 0,
        candidatoIdStr: selecionado.idStr,
        vagaIdStr: widget.vagaIdStr,
        status: 'em_analise',
        dataCandidatura: agora,
        atualizadoEm: agora,
      );
      await getIt<ICandidaturaRepositorio>().salvar(candidatura);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Candidato vinculado com sucesso!'),
          backgroundColor: AppCores.primaria,
        ));
        _carregar();
      }
    } catch (e) {
      debugPrint('[TelaDetalheVaga] Erro ao vincular candidato: $e');
    }
  }

  // ── Editar vaga ────────────────────────────────────────────────────────────

  void _editarVaga() {
    if (_vaga == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => TelaCriarVaga(vagaExistente: _vaga),
        ))
        .then((_) => _carregar());
  }

  // ── Build principal ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: RhosAppBarInterna(
        icone: Icons.work_outline,
        titulo: 'Detalhe da Vaga',
        actions: _vaga != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppCores.textoClaro),
                  tooltip: 'Editar vaga',
                  onPressed: _editarVaga,
                ),
              ]
            : null,
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppCores.primaria))
          : _vaga == null
              ? const Center(child: Text('Vaga não encontrada.'))
              : Column(
                  children: [
                    _buildCabecalho(_vaga!),
                    TabBar(
                      controller: _tab,
                      labelColor: AppCores.primaria,
                      indicatorColor: AppCores.primaria,
                      tabs: const [
                        Tab(text: AppStrings.abaCandidatos),
                        Tab(text: 'Detalhes'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _buildCandidatos(),
                          _buildDetalhes(_vaga!),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ── Cabeçalho ──────────────────────────────────────────────────────────────

  Widget _buildCabecalho(Vaga v) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppCores.primaria.withAlpha(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(v.titulo,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              _badgeStatus(v.status),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (v.senioridade != null)
                _infoChip(
                    Icons.bar_chart_rounded, _labelSenioridade(v.senioridade!)),
              if (v.local != null)
                _infoChip(Icons.location_on_outlined, v.local!),
              if (v.modalidade != null)
                _infoChip(
                    Icons.laptop_outlined, _labelModalidade(v.modalidade!)),
            ],
          ),
          if (v.salarioMin != null || v.salarioMax != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.attach_money,
                    size: 16, color: AppCores.textoSecundario),
                const SizedBox(width: 2),
                Text(
                  _formatarFaixa(v.salarioMin, v.salarioMax),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppCores.textoSecundario,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icone, String texto) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: AppCores.textoSecundario),
          const SizedBox(width: 3),
          Text(texto,
              style: const TextStyle(
                  fontSize: 12, color: AppCores.textoSecundario)),
        ],
      );

  Widget _badgeStatus(String status) {
    final cor = switch (status) {
      'aberta' => Colors.green,
      'em_triagem' => AppCores.cta,
      _ => AppCores.textoSecundario,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.replaceAll('_', ' '),
          style:
              TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
    );
  }

  // ── Aba candidatos ─────────────────────────────────────────────────────────

  Widget _buildCandidatos() {
    // Lista filtrada e ordenada por score DESC
    final candidaturasFiltradas = _candidaturasFiltradas();
    final total = _candidaturas.length;
    final exibindo = candidaturasFiltradas.length;

    return Column(
      children: [
        // ── Botões de ação ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _vincularCandidato,
                  icon: const Icon(Icons.person_add_outlined,
                      color: AppCores.primaria, size: 18),
                  label: const Text('Vincular candidato',
                      style: TextStyle(color: AppCores.primaria, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppCores.primaria),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _calculandoRanking ? null : _calcularRanking,
                  icon: _calculandoRanking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppCores.cta),
                        )
                      : const Icon(Icons.auto_graph,
                          color: AppCores.cta, size: 18),
                  label: Text(
                    _calculandoRanking ? 'Calculando...' : 'Calcular Ranking',
                    style: const TextStyle(color: AppCores.cta, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppCores.cta),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Aviso de score local ────────────────────────────────────────────
        if (_usouScoreLocal)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Text(
              'Score calculado localmente (sem IA)',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        if (_erroRanking != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Text(
              _erroRanking!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),

        // ── R6 Filtros ──────────────────────────────────────────────────────
        if (_rankings.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score mínimo
                Row(
                  children: [
                    Text(
                      'Score mínimo: ${_scoreMinimo.toInt()}%',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppCores.textoSecundario,
                          fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Slider(
                        value: _scoreMinimo,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: AppCores.primaria,
                        onChanged: (v) => setState(() => _scoreMinimo = v),
                      ),
                    ),
                  ],
                ),
                // Status + contador
                Row(
                  children: [
                    const Text('Status:',
                        style: TextStyle(
                            fontSize: 12, color: AppCores.textoSecundario)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filtroStatus,
                      isDense: true,
                      style: const TextStyle(
                          fontSize: 12, color: AppCores.textoPrincipal),
                      items: _opcoesStatus
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _filtroStatus = v);
                        }
                      },
                    ),
                    const Spacer(),
                    Text(
                      'Exibindo $exibindo de $total candidatos',
                      style: const TextStyle(
                          fontSize: 11, color: AppCores.textoSecundario),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        // ── Lista de candidatos ─────────────────────────────────────────────
        Expanded(
          child: candidaturasFiltradas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline,
                          size: 56, color: AppCores.textoSecundario),
                      const SizedBox(height: 12),
                      Text(
                        _candidaturas.isEmpty
                            ? AppStrings.nenhumCandidato
                            : 'Nenhum candidato nos filtros selecionados.',
                        style: const TextStyle(color: AppCores.textoSecundario),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: candidaturasFiltradas.length,
                  itemBuilder: (_, i) {
                    final cand = candidaturasFiltradas[i];
                    final candidatoIdStr = cand.candidatoIdStr ?? '';
                    final candidato = _candidatos[candidatoIdStr];
                    final ranking = _rankings[candidatoIdStr];
                    final score = _scoreDoRanking(ranking);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome + badge status + botão info
                            Row(
                              children: [
                                // Avatar iniciais
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppCores.primaria,
                                  child: Text(
                                    _iniciais(candidato?.nome),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    candidato?.nome ??
                                        'Candidato ${cand.candidatoIdStr ?? cand.candidatoId}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _badgeStatus(cand.status),
                                if (ranking != null)
                                  IconButton(
                                    icon: const Icon(Icons.info_outline,
                                        size: 20, color: AppCores.primaria),
                                    tooltip: 'Detalhes do ranking',
                                    onPressed: () => _mostrarDetalheRanking(
                                        candidato?.nome ?? 'Candidato',
                                        ranking),
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'remover') {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title:
                                              const Text('Remover candidatura'),
                                          content: const Text(
                                              'Confirma remoção desta candidatura?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppCores.cta),
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Remover',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true && cand.idStr != null) {
                                        await getIt<ICandidaturaRepositorio>()
                                            .deletarStr(cand.idStr!);
                                        await getIt<
                                                RankingRepositorioFirestore>()
                                            .apagar(widget.vagaIdStr,
                                                cand.candidatoIdStr!);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content:
                                                Text('Candidatura removida'),
                                            backgroundColor: AppCores.primaria,
                                          ));
                                          _carregar();
                                        }
                                      }
                                    } else if (v == 'refazer') {
                                      // Forçar recalculo ignorando cache
                                      if (cand.candidatoIdStr != null) {
                                        await getIt<
                                                RankingRepositorioFirestore>()
                                            .apagar(widget.vagaIdStr,
                                                cand.candidatoIdStr!);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Cache removido. Recalculando ranking...'),
                                            backgroundColor: AppCores.primaria,
                                          ));
                                        }
                                        await _calcularRanking();
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 'refazer',
                                        child: Text('Refazer ranking')),
                                    const PopupMenuItem(
                                        value: 'remover',
                                        child: Text('Remover candidatura')),
                                  ],
                                ),
                              ],
                            ),

                            // Email
                            if (candidato?.email != null) ...[
                              const SizedBox(height: 2),
                              Text(candidato!.email!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppCores.textoSecundario)),
                            ],

                            // Barra de score (R5)
                            if (ranking != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: (score / 100).clamp(0.0, 1.0),
                                      backgroundColor:
                                          AppCores.primaria.withAlpha(30),
                                      color: AppCores.primaria,
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${score.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppCores.primaria),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Botões de status
                            Row(
                              children: [
                                _botaoStatus(cand, AppStrings.aprovar,
                                    'aprovado', Colors.green),
                                const SizedBox(width: 6),
                                _botaoStatus(cand, AppStrings.emAnalise,
                                    'em_analise', AppCores.primaria),
                                const SizedBox(width: 6),
                                _botaoStatus(cand, AppStrings.reprovar,
                                    'reprovado', AppCores.cta),
                              ],
                            ),

                            // Ver perfil completo
                            if (cand.candidatoIdStr != null) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => context.push(
                                    AppRotas.curriculoCompletoId(
                                        cand.candidatoIdStr!),
                                  ),
                                  icon: const Icon(Icons.person_outline,
                                      size: 16, color: AppCores.primaria),
                                  label: const Text(
                                    'Ver perfil completo',
                                    style: TextStyle(
                                        fontSize: 12, color: AppCores.primaria),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── BottomSheet detalhe de ranking ─────────────────────────────────────────

  void _mostrarDetalheRanking(String nome, Map<String, dynamic> ranking) {
    final justificativa = ranking['justificativa'] as String? ?? '';
    final fortes = (ranking['pontos_fortes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final fracos = (ranking['pontos_fracos'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final score = _scoreDoRanking(ranking);
    final scoresPorEixo =
        (ranking['scores_por_eixo'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final gating = ranking['gating_aprovado'] as bool? ?? true;
    final faltantes = (ranking['requisitos_nao_atendidos'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppCores.textoSecundario.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Título
            Text(nome,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Score IA: ',
                    style: TextStyle(
                        color: AppCores.textoSecundario, fontSize: 13)),
                Text('${score.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppCores.primaria)),
              ],
            ),
            const SizedBox(height: 12),
            if (!gating) ...[
              const Text('Requisitos obrigatorios nao atendidos',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.redAccent)),
              const SizedBox(height: 6),
              ...faltantes.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('- $r', style: const TextStyle(fontSize: 13)),
                  )),
              const SizedBox(height: 12),
            ],
            if (scoresPorEixo.isNotEmpty) ...[
              const Text('Rubrica por eixo (0-5)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppCores.primaria)),
              const SizedBox(height: 6),
              ...scoresPorEixo.entries.map((e) {
                final valor =
                    e.value is num ? (e.value as num).toDouble() : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_labelEixo(e.key),
                          style: const TextStyle(fontSize: 12)),
                      Text(valor.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            // Justificativa
            if (justificativa.isNotEmpty) ...[
              const Text('Justificativa',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppCores.primaria)),
              const SizedBox(height: 4),
              Text(justificativa,
                  style: const TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 16),
            ],
            // Pontos fortes
            if (fortes.isNotEmpty) ...[
              const Text('Pontos fortes',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.green)),
              const SizedBox(height: 6),
              ...fortes.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                            child:
                                Text(p, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            // Pontos fracos
            if (fracos.isNotEmpty) ...[
              const Text('Pontos a desenvolver',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.redAccent)),
              const SizedBox(height: 6),
              ...fracos.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel_outlined,
                            size: 16, color: Colors.redAccent),
                        const SizedBox(width: 6),
                        Expanded(
                            child:
                                Text(p, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Retorna a lista filtrada por score mínimo e status, ordenada por score DESC.
  List<Candidatura> _candidaturasFiltradas() {
    final statusParaFiltro = switch (_filtroStatus) {
      'Aprovado' => 'aprovado',
      'Reprovado' => 'reprovado',
      'Em análise' => 'em_analise',
      _ => null,
    };

    var lista = _candidaturas.where((c) {
      // Filtro de status
      if (statusParaFiltro != null && c.status != statusParaFiltro) {
        return false;
      }
      // Filtro de score mínimo (só aplica se há rankings calculados)
      if (_rankings.isNotEmpty && _scoreMinimo > 0) {
        final idStr = c.candidatoIdStr ?? '';
        final score = _scoreDoRanking(_rankings[idStr]);
        if (score < _scoreMinimo) return false;
      }
      return true;
    }).toList();

    // Ordenar por score DESC (candidatos sem ranking vão para o final)
    if (_rankings.isNotEmpty) {
      lista.sort((a, b) {
        final sa = _scoreDoRanking(_rankings[a.candidatoIdStr ?? '']);
        final sb = _scoreDoRanking(_rankings[b.candidatoIdStr ?? '']);
        return sb.compareTo(sa);
      });
    }

    return lista;
  }

  String _iniciais(String? nome) {
    if (nome == null || nome.isEmpty) return '?';
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
    }
    return partes.first[0].toUpperCase();
  }

  double _scoreDoRanking(Map<String, dynamic>? ranking) {
    if (ranking == null) return 0.0;
    final valor = ranking['score_total'] ?? ranking['score'];
    if (valor is num) return valor.toDouble();
    return 0.0;
  }

  String _labelEixo(String chave) {
    switch (chave) {
      case 'hard_skills':
        return 'Hard skills';
      case 'soft_skills':
        return 'Soft skills';
      case 'experiencia':
        return 'Experiencia';
      case 'formacao':
        return 'Formacao';
      case 'idiomas':
        return 'Idiomas';
      default:
        return chave;
    }
  }

  Widget _botaoStatus(Candidatura c, String label, String status, Color cor) {
    final ativo = c.status == status;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: cor,
          side: BorderSide(color: ativo ? cor : AppCores.textoSecundario),
          backgroundColor: ativo ? cor.withAlpha(25) : null,
          padding: const EdgeInsets.symmetric(vertical: 4),
          textStyle: const TextStyle(fontSize: 11),
        ),
        onPressed: c.idStr != null ? () => _alterarStatus(c, status) : null,
        child: Text(label),
      ),
    );
  }

  // ── Aba detalhes ───────────────────────────────────────────────────────────

  Widget _buildDetalhes(Vaga v) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _secao('Descrição', v.descricao),
        if (v.requisitos != null && v.requisitos!.isNotEmpty)
          _secao(AppStrings.labelRequisitos, v.requisitos!),

        // Hard skills em chips primária
        if (v.habilidades != null && v.habilidades!.isNotEmpty) ...[
          _tituloSecao('Hard Skills (Técnicas)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: v.habilidades!
                .map((h) => Chip(
                      label: Text(h,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      backgroundColor: AppCores.primaria,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Soft skills em chips cta
        if (v.softSkills != null && v.softSkills!.isNotEmpty) ...[
          _tituloSecao('Soft Skills'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: v.softSkills!
                .map((s) => Chip(
                      label: Text(s,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      backgroundColor: AppCores.cta,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Informações estruturadas
        if (v.tipoContrato != null ||
            v.senioridade != null ||
            v.modalidade != null ||
            v.local != null ||
            v.salarioMin != null ||
            v.salarioMax != null) ...[
          _tituloSecao('Informações da vaga'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              if (v.tipoContrato != null)
                _infoItem('Tipo contrato', v.tipoContrato!),
              if (v.senioridade != null)
                _infoItem('Senioridade', _labelSenioridade(v.senioridade!)),
              if (v.modalidade != null)
                _infoItem('Modalidade', _labelModalidade(v.modalidade!)),
              if (v.local != null) _infoItem('Local', v.local!),
              if (v.salarioMin != null || v.salarioMax != null)
                _infoItem('Faixa salarial',
                    _formatarFaixa(v.salarioMin, v.salarioMax)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _secao(String titulo, String conteudo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSecao(titulo),
          const SizedBox(height: 6),
          Text(conteudo),
          const SizedBox(height: 16),
        ],
      );

  Widget _tituloSecao(String titulo) => Text(titulo,
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 14, color: AppCores.primaria));

  Widget _infoItem(String label, String valor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppCores.textoSecundario)),
          Text(valor, style: const TextStyle(fontSize: 14)),
        ],
      );

  String _formatarFaixa(double? min, double? max) {
    String fmt(double v) => 'R\$ ${v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
    if (min != null && max != null) return '${fmt(min)} — ${fmt(max)}';
    if (min != null) return 'A partir de ${fmt(min)}';
    if (max != null) return 'Até ${fmt(max)}';
    return '';
  }

  String _labelSenioridade(String s) => switch (s) {
        'junior' => 'Júnior',
        'pleno' => 'Pleno',
        'senior' => 'Sênior',
        'especialista' => 'Especialista',
        _ => s,
      };

  String _labelModalidade(String m) => switch (m) {
        'presencial' => 'Presencial',
        'remoto' => 'Remoto',
        'hibrido' => 'Híbrido',
        _ => m,
      };
}

// ── Diálogo de busca para vincular candidato ───────────────────────────────

class _DialogoBuscarCandidato extends StatefulWidget {
  const _DialogoBuscarCandidato({required this.candidatos});

  final List<Candidato> candidatos;

  @override
  State<_DialogoBuscarCandidato> createState() =>
      _DialogoBuscarCandidatoState();
}

class _DialogoBuscarCandidatoState extends State<_DialogoBuscarCandidato> {
  final _busca = TextEditingController();
  late List<Candidato> _filtrados;

  @override
  void initState() {
    super.initState();
    _filtrados = widget.candidatos;
    _busca.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _filtrar() {
    final termo = _busca.text.toLowerCase();
    setState(() {
      _filtrados = widget.candidatos
          .where((c) =>
              c.nome.toLowerCase().contains(termo) ||
              (c.email ?? '').toLowerCase().contains(termo))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Vincular candidato',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _busca,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nome ou e-mail...',
                    filled: true,
                    fillColor: AppCores.fundoInput,
                    prefixIcon:
                        Icon(Icons.search, color: AppCores.textoSecundario),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _filtrados.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhum candidato disponível',
                        style: TextStyle(color: AppCores.textoSecundario)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtrados.length,
                    itemBuilder: (_, i) {
                      final c = _filtrados[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppCores.primaria,
                          child: Text(
                            c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(c.nome),
                        subtitle: c.email != null
                            ? Text(c.email!,
                                style: const TextStyle(fontSize: 12))
                            : null,
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
