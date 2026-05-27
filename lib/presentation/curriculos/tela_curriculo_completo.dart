import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/utils/validadores.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/entidades/experiencia.dart';
import 'package:rh_os/domain/entidades/formacao.dart';
import 'package:rh_os/domain/entidades/habilidade.dart';
import 'package:rh_os/domain/entidades/idioma.dart';
import 'package:rh_os/presentation/widgets/avatar_iniciais.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';

class TelaCurriculoCompleto extends ConsumerStatefulWidget {
  const TelaCurriculoCompleto({super.key, required this.candidatoId});

  final String candidatoId;

  @override
  ConsumerState<TelaCurriculoCompleto> createState() =>
      _TelaCurriculoCompletoState();
}

class _TelaCurriculoCompletoState extends ConsumerState<TelaCurriculoCompleto> {
  bool _carregando = true;
  Candidato? _candidato;
  List<Experiencia> _experiencias = [];
  List<Formacao> _formacoes = [];
  List<Habilidade> _habilidades = [];
  List<Idioma> _idiomas = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final repo = getIt<ICandidatoRepositorio>();
    final id = widget.candidatoId;

    try {
      final results = await Future.wait([
        repo.buscarPorIdStr(id),
        repo.listarExperienciasStr(id),
        repo.listarFormacoesStr(id),
        repo.listarHabilidadesStr(id),
        repo.listarIdiomasStr(id),
      ]);
      if (!mounted) return;
      setState(() {
        _candidato = results[0] as Candidato?;
        _experiencias = (results[1] as List).cast<Experiencia>();
        _formacoes = (results[2] as List).cast<Formacao>();
        _habilidades = (results[3] as List).cast<Habilidade>();
        _idiomas = (results[4] as List).cast<Idioma>();
        _carregando = false;
      });
    } catch (e) {
      debugPrint('[TelaCurriculoCompleto] _carregar: $e');
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: const RhosAppBarInterna(
        icone: Icons.person_outline,
        titulo: 'Currículo Completo',
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppCores.primaria))
          : _candidato == null
              ? const Center(child: Text('Candidato não encontrado.'))
              : _buildCorpo(_candidato!),
    );
  }

  Widget _buildCorpo(Candidato c) {
    final telefone = Validadores.normalizarTelefone(c.telefone);
    final cep = Validadores.normalizarCep(c.cep);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCabecalho(c),
        const SizedBox(height: 16),
        if (c.resumo != null && c.resumo!.isNotEmpty) ...[
          _buildSecao('Resumo'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(c.resumo!,
                style: const TextStyle(color: AppCores.textoPrincipal)),
          ),
          const SizedBox(height: 8),
        ],
        _buildSecao('Informações Pessoais'),
        Row(
          children: [
            Expanded(child: _ColunaInfo(label: 'CPF', valor: c.cpf)),
            Expanded(
                child:
                    _ColunaInfo(label: 'Nascimento', valor: c.dataNascimento)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _ColunaInfo(label: 'E-mail', valor: c.email)),
            Expanded(child: _ColunaInfo(label: 'Telefone', valor: telefone)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _ColunaInfo(label: 'Cidade', valor: c.cidade)),
            Expanded(child: _ColunaInfo(label: 'Estado', valor: c.estado)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
                child: _ColunaInfo(
                    label: 'Endereço',
                    valor: [c.logradouro, c.numero, c.bairro]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(', '))),
            Expanded(child: _ColunaInfo(label: 'CEP', valor: cep)),
          ],
        ),
        const SizedBox(height: 16),
        if (_experiencias.isNotEmpty) ...[
          _buildSecao('Experiências'),
          ..._experiencias.map((e) => _CardExperiencia(exp: e)),
          const SizedBox(height: 8),
        ],
        if (_formacoes.isNotEmpty) ...[
          _buildSecao('Formação'),
          ..._formacoes.map((f) => _CardFormacao(form: f)),
          const SizedBox(height: 8),
        ],
        if (_habilidades.isNotEmpty) ...[
          _buildSecao('Habilidades'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _habilidades
                  .map((h) => Chip(
                        label: Text(h.nome,
                            style: const TextStyle(color: AppCores.textoClaro)),
                        backgroundColor: AppCores.primaria,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_idiomas.isNotEmpty) ...[
          _buildSecao('Idiomas'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _idiomas
                  .map((i) => Chip(
                        label: Text('${i.nome} — ${i.nivel}',
                            style: const TextStyle(color: AppCores.textoClaro)),
                        backgroundColor: AppCores.cta,
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCabecalho(Candidato c) {
    return Row(
      children: [
        AvatarIniciais(nome: c.nome, radius: 36),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.nome,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              if (c.cidade != null || c.estado != null)
                Text(
                  [c.cidade, c.estado]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(', '),
                  style: const TextStyle(color: AppCores.textoSecundario),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecao(String titulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppCores.primaria)),
        const Divider(color: AppCores.primaria, thickness: 1),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ColunaInfo extends StatelessWidget {
  const _ColunaInfo({required this.label, required this.valor});

  final String label;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppCores.textoSecundario)),
          Text(valor?.isNotEmpty == true ? valor! : '—',
              style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _CardExperiencia extends StatelessWidget {
  const _CardExperiencia({required this.exp});

  final Experiencia exp;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exp.cargo,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(exp.empresa, style: const TextStyle(color: AppCores.primaria)),
            Text(
              '${exp.dataInicio} — ${exp.atual ? "Atual" : (exp.dataFim ?? "")}',
              style: const TextStyle(
                  fontSize: 12, color: AppCores.textoSecundario),
            ),
            if (exp.descricao != null && exp.descricao!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(exp.descricao!, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardFormacao extends StatelessWidget {
  const _CardFormacao({required this.form});

  final Formacao form;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(form.curso,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(form.instituicao,
                style: const TextStyle(color: AppCores.primaria)),
            Text(
              '${form.dataInicio} — ${form.emAndamento ? "Em andamento" : (form.dataFim ?? "")}',
              style: const TextStyle(
                  fontSize: 12, color: AppCores.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}
