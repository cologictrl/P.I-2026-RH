import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rh_os/core/constantes/app_rotas.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/domain/casos_de_uso/vagas/listar_vagas.dart';
import 'package:rh_os/domain/repositorios/i_candidatura_repositorio.dart';
import 'package:rh_os/domain/repositorios/i_vaga_repositorio.dart';
import 'package:rh_os/domain/entidades/vaga.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';

class TelaListaVagas extends ConsumerStatefulWidget {
  const TelaListaVagas({super.key});

  @override
  ConsumerState<TelaListaVagas> createState() => _TelaListaVagasState();
}

class _TelaListaVagasState extends ConsumerState<TelaListaVagas> {
  static const _filtros = [
    ('todas', 'Todas'),
    ('aberta', 'Abertas'),
    ('em_triagem', 'Em triagem'),
    ('encerrada', 'Encerradas'),
  ];

  String _filtroAtivo = 'todas';
  List<Vaga> _vagas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // D4: usa caso de uso ListarVagas em vez do repositório diretamente.
  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final List<Vaga> lista;
      if (_filtroAtivo == 'todas') {
        lista = await getIt<ListarVagas>().executar();
      } else {
        lista = await getIt<IVagaRepositorio>().listarPorStatus(_filtroAtivo);
      }
      if (!mounted) return;
      setState(() {
        _vagas = lista;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('[TelaListaVagas] Erro ao carregar: $e');
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  // D1: usa idStr como identificador principal para excluir vaga.
  Future<void> _excluir(Vaga v) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.confirmarExclusao),
        content: Text('Excluir a vaga "${v.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.excluir,
                style: TextStyle(color: AppCores.cta)),
          ),
        ],
      ),
    );
    if (conf == true && v.idStr != null) {
      try {
        await getIt<IVagaRepositorio>().deletarPorIdStr(v.idStr!);
        _carregar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(AppStrings.excluido),
              backgroundColor: AppCores.primaria));
        }
      } catch (e) {
        debugPrint('[TelaListaVagas] Erro ao excluir vaga: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: const RhosAppBarInterna(
        icone: Icons.work_outline,
        titulo: AppStrings.tituloVagas,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppCores.cta,
        onPressed: () =>
            context.push(AppRotas.novaVaga).then((_) => _carregar()),
        child: const Icon(Icons.add, color: AppCores.textoClaro),
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(color: AppCores.primaria))
                : _vagas.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_off_outlined,
                                size: 64, color: AppCores.textoSecundario),
                            SizedBox(height: 12),
                            Text('Nenhuma vaga encontrada.',
                                style:
                                    TextStyle(color: AppCores.textoSecundario)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        child: ListView.builder(
                          itemCount: _vagas.length,
                          itemBuilder: (_, i) =>
                              _CardVaga(vaga: _vagas[i], aoExcluir: _excluir),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _filtros.map((f) {
          final chave = f.$1;
          final label = f.$2;
          final sel = _filtroAtivo == chave;
          return GestureDetector(
            onTap: () {
              setState(() => _filtroAtivo = chave);
              _carregar();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppCores.primaria : AppCores.fundoInput,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    color: sel ? AppCores.textoClaro : AppCores.textoPrincipal,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CardVaga extends ConsumerStatefulWidget {
  const _CardVaga({required this.vaga, required this.aoExcluir});

  final Vaga vaga;
  final Future<void> Function(Vaga) aoExcluir;

  @override
  ConsumerState<_CardVaga> createState() => _CardVagaState();
}

class _CardVagaState extends ConsumerState<_CardVaga> {
  int _totalCandidaturas = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // D1: usa idStr para listar candidaturas via Firestore.
  Future<void> _carregar() async {
    final idStr = widget.vaga.idStr;
    if (idStr == null || idStr.isEmpty) return;
    try {
      final lista =
          await getIt<ICandidaturaRepositorio>().listarPorVagaStr(idStr);
      if (!mounted) return;
      setState(() => _totalCandidaturas = lista.length);
    } catch (e) {
      debugPrint('[CardVaga] Erro ao contar candidaturas: $e');
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'aberta':
        return Colors.green;
      case 'em_triagem':
        return AppCores.cta;
      default:
        return AppCores.textoSecundario;
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vaga;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        // D1: navega usando idStr (String) em vez de id (int).
        onTap: v.idStr != null
            ? () => context.push(AppRotas.detalheVagaId(v.idStr!))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(v.titulo,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _corStatus(v.status).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(v.status,
                        style: TextStyle(
                            fontSize: 11,
                            color: _corStatus(v.status),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (v.local != null && v.local!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppCores.textoSecundario),
                    const SizedBox(width: 4),
                    Text(v.local!,
                        style: const TextStyle(
                            fontSize: 13, color: AppCores.textoSecundario)),
                  ],
                ),
              ],
              if (v.tipoContrato != null || v.salario != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (v.tipoContrato != null)
                      Text(v.tipoContrato!,
                          style: const TextStyle(
                              fontSize: 12, color: AppCores.textoSecundario)),
                    if (v.tipoContrato != null && v.salario != null)
                      const Text(' · ',
                          style: TextStyle(color: AppCores.textoSecundario)),
                    if (v.salario != null)
                      Text(v.salario!,
                          style: const TextStyle(
                              fontSize: 12, color: AppCores.textoSecundario)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 16, color: AppCores.primaria),
                      const SizedBox(width: 4),
                      Text('$_totalCandidaturas candidatura(s)',
                          style: const TextStyle(
                              fontSize: 12, color: AppCores.primaria)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppCores.cta, size: 20),
                    onPressed: () => widget.aoExcluir(v),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
