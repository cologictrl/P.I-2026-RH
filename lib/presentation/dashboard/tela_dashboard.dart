import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';
import 'package:rh_os/domain/repositorios/i_candidatura_repositorio.dart';
import 'package:rh_os/domain/repositorios/i_vaga_repositorio.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';

class TelaDashboard extends ConsumerStatefulWidget {
  const TelaDashboard({super.key});

  @override
  ConsumerState<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends ConsumerState<TelaDashboard> {
  bool _carregando = true;
  int _totalCandidatos = 0;
  int _vagasAbertas = 0;
  Map<String, int> _porStatus = {};
  List<Map<String, dynamic>> _topHabilidades = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final results = await Future.wait([
      getIt<ICandidatoRepositorio>().contarTotal(),
      getIt<IVagaRepositorio>().contarPorStatus('aberta'),
      getIt<ICandidaturaRepositorio>().contarTodosPorStatus(),
      getIt<ICandidatoRepositorio>().listarTopHabilidades(5),
    ]);
    if (!mounted) return;
    setState(() {
      _totalCandidatos = results[0] as int;
      _vagasAbertas = results[1] as int;
      _porStatus = results[2] as Map<String, int>;
      _topHabilidades = (results[3] as List).cast<Map<String, dynamic>>();
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: const RhosAppBarInterna(
        icone: Icons.bar_chart_outlined,
        titulo: AppStrings.tituloDashboard,
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppCores.primaria))
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCards(),
                  const SizedBox(height: 20),
                  if (_porStatus.isNotEmpty) ...[
                    _buildTitulo(AppStrings.distribuicao),
                    const SizedBox(height: 8),
                    _buildPie(),
                    const SizedBox(height: 20),
                  ],
                  if (_topHabilidades.isNotEmpty) ...[
                    _buildTitulo(AppStrings.topHabilidades),
                    const SizedBox(height: 8),
                    _buildBar(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCards() {
    final aprovados = _porStatus['aprovado'] ?? 0;
    final emAnalise = _porStatus['em_analise'] ?? 0;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _Kpi(
            label: AppStrings.totalCandidatos,
            valor: _totalCandidatos,
            cor: AppCores.primaria,
            icone: Icons.people_outline),
        _Kpi(
            label: AppStrings.vagasAbertas,
            valor: _vagasAbertas,
            cor: Colors.green,
            icone: Icons.work_outline),
        _Kpi(
            label: AppStrings.aprovados,
            valor: aprovados,
            cor: Colors.teal,
            icone: Icons.check_circle_outline),
        _Kpi(
            label: AppStrings.emAnaliseLabel,
            valor: emAnalise,
            cor: AppCores.cta,
            icone: Icons.hourglass_empty_outlined),
      ],
    );
  }

  Widget _buildPie() {
    final entries = _porStatus.entries.toList();
    final cores = [
      AppCores.primaria,
      AppCores.cta,
      Colors.green,
      Colors.teal,
      Colors.blueGrey,
    ];
    final sections = List.generate(entries.length, (i) {
      final e = entries[i];
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.key}\n${e.value}',
        color: cores[i % cores.length],
        radius: 80,
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
      );
    });
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 30,
        ),
      ),
    );
  }

  Widget _buildBar() {
    final maxY = _topHabilidades
        .map((h) => (h['total'] as int).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final grupos = List.generate(_topHabilidades.length, (i) {
      final total = (_topHabilidades[i]['total'] as int).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total,
            color: AppCores.primaria,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY + 1,
          barGroups: grupos,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _topHabilidades.length) {
                    return const SizedBox.shrink();
                  }
                  final nome =
                      _topHabilidades[idx]['nome'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      nome.length > 8 ? '${nome.substring(0, 8)}…' : nome,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppCores.textoSecundario),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitulo(String titulo) {
    return Text(titulo,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppCores.primaria));
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.valor,
    required this.cor,
    required this.icone,
  });

  final String label;
  final int valor;
  final Color cor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withAlpha(60)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$valor',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cor)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppCores.textoSecundario)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
