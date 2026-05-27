import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/data/repositorios/ranking_repositorio_firestore.dart';
import 'package:rh_os/domain/casos_de_uso/vagas/salvar_vaga.dart';
import 'package:rh_os/domain/entidades/vaga.dart';
import 'package:rh_os/presentation/widgets/botao_cta.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';

// Tela de criacao e edicao de vagas.
// Quando [vagaExistente] e fornecida, opera em modo de edicao.
class TelaCriarVaga extends ConsumerStatefulWidget {
  const TelaCriarVaga({super.key, this.vagaExistente});

  final Vaga? vagaExistente;

  @override
  ConsumerState<TelaCriarVaga> createState() => _TelaCriarVagaState();
}

class _TelaCriarVagaState extends ConsumerState<TelaCriarVaga> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _requisitosCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _tipoContratoCtrl = TextEditingController();
  final _salarioMinCtrl = TextEditingController();
  final _salarioMaxCtrl = TextEditingController();
  final _habilidadeCtrl = TextEditingController();
  final _softSkillCtrl = TextEditingController();

  String? _senioridade;
  String? _modalidade;
  List<String> _habilidades = [];
  List<String> _softSkills = [];
  bool _salvando = false;

  bool get _modoEdicao => widget.vagaExistente != null;

  static const _opcoesSenioridade = [
    ('junior', 'Júnior'),
    ('pleno', 'Pleno'),
    ('senior', 'Sênior'),
    ('especialista', 'Especialista'),
  ];

  static const _opcoesModalidade = [
    ('presencial', 'Presencial'),
    ('remoto', 'Remoto'),
    ('hibrido', 'Híbrido'),
  ];

  @override
  void initState() {
    super.initState();
    // Preenche os campos se for modo de edicao
    final v = widget.vagaExistente;
    if (v != null) {
      _tituloCtrl.text = v.titulo;
      _descricaoCtrl.text = v.descricao;
      _requisitosCtrl.text = v.requisitos ?? '';
      _localCtrl.text = v.local ?? '';
      _tipoContratoCtrl.text = v.tipoContrato ?? '';
      _salarioMinCtrl.text =
          v.salarioMin != null ? v.salarioMin!.toStringAsFixed(0) : '';
      _salarioMaxCtrl.text =
          v.salarioMax != null ? v.salarioMax!.toStringAsFixed(0) : '';
      _senioridade = v.senioridade;
      _modalidade = v.modalidade;
      _habilidades = List.from(v.habilidades ?? []);
      _softSkills = List.from(v.softSkills ?? []);
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _requisitosCtrl.dispose();
    _localCtrl.dispose();
    _tipoContratoCtrl.dispose();
    _salarioMinCtrl.dispose();
    _salarioMaxCtrl.dispose();
    _habilidadeCtrl.dispose();
    _softSkillCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    // 'criadoPor' é campo legado (int) — não usado no contexto Firestore.
    final agora = DateTime.now().toIso8601String();

    final min = double.tryParse(_salarioMinCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_salarioMaxCtrl.text.replaceAll(',', '.'));

    final vaga = Vaga(
      idStr: widget.vagaExistente?.idStr,
      titulo: _tituloCtrl.text.trim(),
      descricao: _descricaoCtrl.text.trim(),
      requisitos: _requisitosCtrl.text.trim().isNotEmpty
          ? _requisitosCtrl.text.trim()
          : null,
      local: _localCtrl.text.trim().isNotEmpty ? _localCtrl.text.trim() : null,
      tipoContrato: _tipoContratoCtrl.text.trim().isNotEmpty
          ? _tipoContratoCtrl.text.trim()
          : null,
      salario: null, // legado — usando salarioMin/salarioMax
      status: widget.vagaExistente?.status ?? 'aberta',
      criadoPor: null, // campo int legado — não utilizado no contexto Firestore
      criadoEm: widget.vagaExistente?.criadoEm ?? agora,
      atualizadoEm: agora,
      senioridade: _senioridade,
      modalidade: _modalidade,
      salarioMin: min,
      salarioMax: max,
      habilidades: _habilidades.isNotEmpty ? List.from(_habilidades) : null,
      softSkills: _softSkills.isNotEmpty ? List.from(_softSkills) : null,
    );

    await getIt<SalvarVaga>().executar(vaga);
    if (_modoEdicao && vaga.idStr != null) {
      await getIt<RankingRepositorioFirestore>().apagarPorVaga(vaga.idStr!);
    }
    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          _modoEdicao ? 'Vaga atualizada com sucesso!' : AppStrings.vagaCriada),
      backgroundColor: AppCores.primaria,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: RhosAppBarInterna(
        icone: _modoEdicao ? Icons.edit_outlined : Icons.add_box_outlined,
        titulo: _modoEdicao ? 'Editar Vaga' : AppStrings.criarVaga,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Campos textuais basicos
            _campo(AppStrings.labelTitulo, _tituloCtrl, obrigatorio: true),
            const SizedBox(height: 16),
            _campo(AppStrings.labelDescricao, _descricaoCtrl,
                obrigatorio: true, linhas: 4),
            const SizedBox(height: 16),
            _campo(AppStrings.labelRequisitos, _requisitosCtrl, linhas: 3),
            const SizedBox(height: 16),
            _campo('Local (ex: São Paulo - SP)', _localCtrl),
            const SizedBox(height: 16),
            _campo('Tipo de contrato', _tipoContratoCtrl),
            const SizedBox(height: 16),

            // Senioridade
            DropdownButtonFormField<String>(
              value: _senioridade, // ignore: deprecated_member_use
              decoration: const InputDecoration(
                labelText: 'Senioridade',
                filled: true,
                fillColor: AppCores.fundoInput,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              items: _opcoesSenioridade
                  .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _senioridade = v),
            ),
            const SizedBox(height: 16),

            // Modalidade
            DropdownButtonFormField<String>(
              value: _modalidade, // ignore: deprecated_member_use
              decoration: const InputDecoration(
                labelText: 'Modalidade',
                filled: true,
                fillColor: AppCores.fundoInput,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              items: _opcoesModalidade
                  .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _modalidade = v),
            ),
            const SizedBox(height: 16),

            // Faixa salarial — dois campos numericos em Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salarioMinCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                    ],
                    validator: _validarFaixaSalarial,
                    decoration: const InputDecoration(
                      labelText: 'Salário mínimo',
                      prefixText: 'R\$ ',
                      filled: true,
                      fillColor: AppCores.fundoInput,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salarioMaxCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                    ],
                    validator: _validarFaixaSalarial,
                    decoration: const InputDecoration(
                      labelText: 'Salário máximo',
                      prefixText: 'R\$ ',
                      filled: true,
                      fillColor: AppCores.fundoInput,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hard skills (tecnicas)
            _secaoTitulo('Hard Skills (Técnicas)'),
            _buildChips(
              lista: _habilidades,
              ctrl: _habilidadeCtrl,
              hint: 'Ex: Flutter, React, Python',
              onAdd: _adicionarHabilidade,
              onRemove: (h) => setState(() => _habilidades.remove(h)),
              corChip: AppCores.primaria,
            ),
            const SizedBox(height: 20),

            // Soft skills (comportamentais)
            _secaoTitulo('Soft Skills'),
            _buildChips(
              lista: _softSkills,
              ctrl: _softSkillCtrl,
              hint: 'Ex: Comunicação, Liderança, Trabalho em equipe',
              onAdd: _adicionarSoftSkill,
              onRemove: (s) => setState(() => _softSkills.remove(s)),
              corChip: AppCores.cta,
            ),
            const SizedBox(height: 32),

            BotaoCta(
              label: _modoEdicao ? 'Atualizar Vaga' : AppStrings.salvar,
              carregando: _salvando,
              aoPresionar: _salvar,
            ),
          ],
        ),
      ),
    );
  }

  // Campo de texto reutilizavel
  Widget _campo(
    String label,
    TextEditingController ctrl, {
    bool obrigatorio = false,
    int linhas = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: linhas,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppCores.fundoInput,
        border: const OutlineInputBorder(borderSide: BorderSide.none),
      ),
      validator: obrigatorio
          ? (v) =>
              (v == null || v.trim().isEmpty) ? AppStrings.erroCampoObrig : null
          : null,
    );
  }

  // Titulo de secao dentro do formulario
  Widget _secaoTitulo(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppCores.primaria,
          ),
        ),
      );

  // Chips dinamicos com campo de adicao
  Widget _buildChips({
    required List<String> lista,
    required TextEditingController ctrl,
    required String hint,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
    required Color corChip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lista.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: lista
                .map(
                  (item) => Chip(
                    label: Text(
                      item,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: corChip,
                    deleteIconColor: Colors.white70,
                    onDeleted: () => onRemove(item),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: AppCores.fundoInput,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle, color: AppCores.primaria),
              tooltip: 'Adicionar',
            ),
          ],
        ),
      ],
    );
  }

  // Adiciona hard skill, suportando multiplos separados por virgula
  void _adicionarHabilidade() {
    final texto = _habilidadeCtrl.text.trim();
    if (texto.isEmpty) return;
    final itens = texto
        .split(RegExp(r'[,;\n|/]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() {
      for (final item in itens) {
        if (!_habilidades.contains(item)) _habilidades.add(item);
      }
    });
    _habilidadeCtrl.clear();
  }

  // Adiciona soft skill, suportando multiplos separados por virgula
  void _adicionarSoftSkill() {
    final texto = _softSkillCtrl.text.trim();
    if (texto.isEmpty) return;
    final itens = texto
        .split(RegExp(r'[,;\n|/]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() {
      for (final item in itens) {
        if (!_softSkills.contains(item)) _softSkills.add(item);
      }
    });
    _softSkillCtrl.clear();
  }

  String? _validarFaixaSalarial(String? _) {
    final min = double.tryParse(_salarioMinCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_salarioMaxCtrl.text.replaceAll(',', '.'));
    if (min != null && max != null && min > max) {
      return 'Salario minimo deve ser menor ou igual ao maximo.';
    }
    return null;
  }
}
