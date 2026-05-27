// Tela de listagem e gerenciamento de entrevistas agendadas.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/tema/app_estilos.dart';
import 'package:rh_os/data/repositorios/entrevista_repositorio_firestore.dart';
import 'package:rh_os/domain/entidades/entrevista.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaEntrevistas extends StatefulWidget {
  const TelaEntrevistas({super.key});

  @override
  State<TelaEntrevistas> createState() => _TelaEntrevistasState();
}

class _TelaEntrevistasState extends State<TelaEntrevistas> {
  String _filtro = 'Todas';
  List<Entrevista> _entrevistas = [];
  bool _carregando = true;
  String _perfil = '';
  String _uid = '';

  final _repositorio = getIt<EntrevistaRepositorioFirestore>();

  static const _filtros = ['Todas', 'Pendentes', 'Confirmadas', 'Canceladas'];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ── Carregamento ───────────────────────────────────────────────────────────

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _uid = prefs.getString('usuario_uid') ?? '';

      // Buscar perfil do Firestore
      if (_uid.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_uid)
            .get();
        if (doc.exists) {
          _perfil = doc.data()?['perfil'] as String? ?? '';
        }
      }

      List<Entrevista> entrevistas;
      if (_perfil == 'admin' || _perfil == 'recrutador') {
        // Admin e recrutador: todas as entrevistas
        entrevistas = await _repositorio.listarTodas();
      } else {
        // Candidato: buscar o idStr do candidato pelo uid e filtrar
        final candidatoRepo = getIt<ICandidatoRepositorio>();
        final uid = FirebaseAuth.instance.currentUser?.uid ?? _uid;
        final candidato = await candidatoRepo.buscarPorUsuarioUid(uid);
        if (candidato?.idStr != null) {
          entrevistas =
              await _repositorio.listarPorCandidato(candidato!.idStr!);
        } else {
          entrevistas = [];
        }
      }

      if (!mounted) return;
      setState(() {
        _entrevistas = entrevistas;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('[TelaEntrevistas] Erro ao carregar: $e');
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  // ── Filtro local ───────────────────────────────────────────────────────────

  List<Entrevista> get _filtradas {
    if (_filtro == 'Todas') return _entrevistas;
    final statusAlvo = switch (_filtro) {
      'Pendentes' => 'pendente',
      'Confirmadas' => 'confirmada',
      'Canceladas' => 'cancelada',
      _ => '',
    };
    return _entrevistas.where((e) => e.status == statusAlvo).toList();
  }

  // ── Ações de status ────────────────────────────────────────────────────────

  Future<void> _confirmar(Entrevista e) async {
    await _repositorio.atualizarStatus(e.idStr!, 'confirmada');
    _carregar();
  }

  Future<void> _cancelar(Entrevista e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar entrevista'),
        content: const Text('Tem certeza que deseja cancelar esta entrevista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar entrevista',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repositorio.atualizarStatus(e.idStr!, 'cancelada');
      _carregar();
    }
  }

  Future<void> _reagendar(Entrevista e) async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(e.dataHora) ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          DateTime.tryParse(e.dataHora) ?? DateTime.now()),
    );
    if (hora == null || !mounted) return;

    final novaDataHora =
        DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    await _repositorio.reagendar(e.idStr!, novaDataHora.toIso8601String());
    _carregar();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: const RhosAppBarInterna(
        icone: Icons.calendar_month,
        titulo: 'Entrevistas',
      ),
      body: Column(
        children: [
          // Chips de filtro horizontal
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _filtros.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filtros[i];
                final ativo = _filtro == f;
                return ChoiceChip(
                  label: Text(f,
                      style: TextStyle(
                        fontSize: 13,
                        color: ativo ? Colors.white : AppCores.textoSecundario,
                      )),
                  selected: ativo,
                  selectedColor: AppCores.primaria,
                  backgroundColor: AppCores.fundoCard,
                  onSelected: (_) => setState(() => _filtro = f),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Conteúdo
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(color: AppCores.primaria))
                : _filtradas.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        color: AppCores.primaria,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: _filtradas.length,
                          itemBuilder: (_, i) => _EntrevistaCard(
                            entrevista: _filtradas[i],
                            onConfirmar: _confirmar,
                            onCancelar: _cancelar,
                            onReagendar: _reagendar,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 64, color: AppCores.textoSecundario),
            const SizedBox(height: 16),
            Text(
              'Nenhuma entrevista agendada',
              style: AppEstilos.valorCampo
                  .copyWith(color: AppCores.textoSecundario),
            ),
          ],
        ),
      );
}

// ── Card individual de entrevista ──────────────────────────────────────────

class _EntrevistaCard extends StatelessWidget {
  const _EntrevistaCard({
    required this.entrevista,
    required this.onConfirmar,
    required this.onCancelar,
    required this.onReagendar,
  });

  final Entrevista entrevista;
  final Future<void> Function(Entrevista) onConfirmar;
  final Future<void> Function(Entrevista) onCancelar;
  final Future<void> Function(Entrevista) onReagendar;

  @override
  Widget build(BuildContext context) {
    final dataHora = DateTime.tryParse(entrevista.dataHora);
    final dataFormatada = dataHora != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dataHora)
        : entrevista.dataHora;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome do candidato + badge de status
            Row(
              children: [
                Expanded(
                  child: Text(
                    entrevista.candidatoNome ?? 'Candidato',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _BadgeStatus(status: entrevista.status),
              ],
            ),

            // Título da vaga
            if (entrevista.vagaTitulo != null) ...[
              const SizedBox(height: 2),
              Text(
                entrevista.vagaTitulo!,
                style: const TextStyle(
                    fontSize: 13, color: AppCores.textoSecundario),
              ),
            ],

            const SizedBox(height: 6),

            // Data e hora
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 15, color: AppCores.textoSecundario),
                const SizedBox(width: 4),
                Text(
                  dataFormatada,
                  style: const TextStyle(
                      fontSize: 13, color: AppCores.textoSecundario),
                ),
              ],
            ),

            // Observações
            if (entrevista.observacoes != null &&
                entrevista.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entrevista.observacoes!,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppCores.textoSecundario,
                    fontStyle: FontStyle.italic),
              ),
            ],

            const SizedBox(height: 10),

            // Botões de ação conforme status
            _buildBotoes(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoes(BuildContext context) {
    final idStr = entrevista.idStr;
    if (idStr == null) return const SizedBox.shrink();

    final status = entrevista.status;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        // pendente → Confirmar + Cancelar
        if (status == 'pendente') ...[
          _Botao(
            label: 'Confirmar',
            cor: Colors.green,
            onTap: () => onConfirmar(entrevista),
          ),
          _Botao(
            label: 'Cancelar',
            cor: Colors.redAccent,
            onTap: () => onCancelar(entrevista),
          ),
        ],

        // confirmada → Cancelar + Reagendar
        if (status == 'confirmada') ...[
          _Botao(
            label: 'Cancelar',
            cor: Colors.redAccent,
            onTap: () => onCancelar(entrevista),
          ),
          _Botao(
            label: 'Reagendar',
            cor: const Color(0xFF1565C0),
            onTap: () => onReagendar(entrevista),
          ),
        ],

        // cancelada → Reagendar
        if (status == 'cancelada')
          _Botao(
            label: 'Reagendar',
            cor: const Color(0xFF1565C0),
            onTap: () => onReagendar(entrevista),
          ),

        // reagendar → Confirmar nova data + Cancelar
        if (status == 'reagendar') ...[
          _Botao(
            label: 'Confirmar nova data',
            cor: Colors.green,
            onTap: () => onConfirmar(entrevista),
          ),
          _Botao(
            label: 'Cancelar',
            cor: Colors.redAccent,
            onTap: () => onCancelar(entrevista),
          ),
        ],
      ],
    );
  }
}

// ── Badge colorido de status ───────────────────────────────────────────────

class _BadgeStatus extends StatelessWidget {
  const _BadgeStatus({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, cor) = switch (status) {
      'pendente' => ('Pendente', const Color(0xFFF48C68)),
      'confirmada' => ('Confirmada', Colors.green),
      'cancelada' => ('Cancelada', Colors.redAccent),
      'reagendar' => ('Reagendar', Colors.blueAccent),
      _ => (status, AppCores.textoSecundario),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Botão de ação compacto ─────────────────────────────────────────────────

class _Botao extends StatelessWidget {
  const _Botao({required this.label, required this.cor, required this.onTap});
  final String label;
  final Color cor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: cor,
        side: BorderSide(color: cor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
