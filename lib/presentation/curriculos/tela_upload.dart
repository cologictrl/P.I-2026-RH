import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/data/repositorios/ranking_repositorio_firestore.dart';
import 'package:rh_os/data/servicos/auditoria_service.dart';
import 'package:rh_os/core/utils/validadores.dart';
import 'package:rh_os/domain/casos_de_uso/candidatos/merge_candidato.dart';
import 'package:rh_os/domain/casos_de_uso/candidatos/verificar_duplicidade.dart';
import 'package:rh_os/domain/casos_de_uso/extrair_dados_curriculo.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/presentation/widgets/botao_cta.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Estado { inicial, carregando, resultado }

class TelaUpload extends ConsumerStatefulWidget {
  const TelaUpload({super.key});

  @override
  ConsumerState<TelaUpload> createState() => _TelaUploadState();
}

class _TelaUploadState extends ConsumerState<TelaUpload> {
  _Estado _estado = _Estado.inicial;
  Map<String, dynamic> _dados = {};
  final Map<String, TextEditingController> _editaveis = {};
  final TextEditingController _habilidadeCtrl = TextEditingController();
  bool _salvando = false;
  // E3: qualidade e origem da extração.
  String _origemExtracao = '';
  int _camposPreenchidos = 0;
  static const int _totalCampos = 12;
  String _mensagemCarregando = 'Extraindo dados do currículo...';

  static const _campos = [
    ('nome', 'Nome'),
    ('email', 'E-mail'),
    ('telefone', 'Telefone'),
    ('cpf', 'CPF'),
    ('dataNascimento', 'Nascimento'),
    ('logradouro', 'Rua'),
    ('numero', 'Número'),
    ('bairro', 'Bairro'),
    ('cep', 'CEP'),
    ('cidade', 'Cidade'),
    ('estado', 'Estado'),
    ('resumo', 'Resumo'),
  ];

  @override
  void dispose() {
    for (final c in _editaveis.values) {
      c.dispose();
    }
    _habilidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionar() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true,
    );

    if (resultado == null || resultado.files.isEmpty) return;

    final arquivo = resultado.files.first;
    final bytes = arquivo.bytes;
    if (bytes == null) return;

    final extensao = (arquivo.extension ?? 'pdf').toLowerCase();

    setState(() {
      _estado = _Estado.carregando;
      // E8: mensagem inicial antes de qualquer processamento.
      _mensagemCarregando = 'Preparando arquivo...';
      _origemExtracao = '';
    });

    final extrator = ExtrairDadosCurriculo();
    final dados = await extrator.executarComBytes(
      bytes,
      extensao,
      onProgresso: (msg) {
        if (mounted) {
          // E8: rastrear origem pela mensagem de progresso.
          setState(() {
            _mensagemCarregando = msg;
            if (msg.contains('Gemini')) {
              _origemExtracao = 'Gemini 2.5 Flash';
            } else if (msg.contains('regex') || msg.contains('arquivo')) {
              _origemExtracao = 'regex (fallback)';
            }
          });
        }
      },
    );

    if (!mounted) return;

    _dados = dados;
    _prepararListas();
    _corrigirTelefoneCepDados();
    _prepararEditaveis();
    // E3: calcular qualidade após extração.
    _calcularQualidade();
    setState(() => _estado = _Estado.resultado);
  }

  void _prepararListas() {
    _dados['experiencias'] ??= <Map<String, dynamic>>[];
    _dados['formacoes'] ??= <Map<String, dynamic>>[];
    _dados['habilidades'] ??= <String>[];
    _dados['idiomas'] ??= <Map<String, dynamic>>[];
  }

  void _prepararEditaveis() {
    for (final c in _editaveis.values) {
      c.dispose();
    }
    _editaveis.clear();
    for (final (chave, _) in _campos) {
      final val = _dados[chave];
      final texto = val is String ? val.trim() : '';
      if (texto.isEmpty) {
        _dados[chave] = '';
      }
      _editaveis[chave] = TextEditingController(text: texto);
    }
  }

  bool _campoInvalido(String chave, String valor) {
    switch (chave) {
      case 'email':
        return Validadores.email(valor) != null;
      case 'cpf':
        return Validadores.cpf(valor) != null;
      case 'telefone':
        return Validadores.telefone(valor) != null;
      case 'cep':
        return Validadores.cep(valor) != null;
      default:
        return false;
    }
  }

  void _mostrarAvisoMinimos() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preencha o resumo e adicione ao menos 1 habilidade.'),
        backgroundColor: AppCores.cta,
      ),
    );
  }

  void _corrigirTelefoneCepDados() {
    final telefone = _dados['telefone'] as String?;
    final cep = _dados['cep'] as String?;

    final telDigits = _digits(telefone);
    final cepDigits = _digits(cep);

    if (!_vazio(telefone) && _ehCep(telDigits) && _vazio(cep)) {
      _dados['cep'] = telefone;
      _dados['telefone'] = '';
      return;
    }

    if (!_vazio(cep) && _ehTelefone(cepDigits) && _vazio(telefone)) {
      _dados['telefone'] = cep;
      _dados['cep'] = '';
    }

    final telFmt =
        Validadores.normalizarTelefone(_dados['telefone'] as String?);
    final cepFmt = Validadores.normalizarCep(_dados['cep'] as String?);

    if (telFmt != null && !_campoInvalido('telefone', telFmt)) {
      _dados['telefone'] = telFmt;
    } else if (!_vazio(_dados['telefone'] as String?)) {
      _dados['telefone'] = '';
    }

    if (cepFmt != null && !_campoInvalido('cep', cepFmt)) {
      _dados['cep'] = cepFmt;
    } else if (!_vazio(_dados['cep'] as String?)) {
      _dados['cep'] = '';
    }
  }

  String? _digits(String? valor) {
    if (valor == null) return null;
    final d = valor.replaceAll(RegExp(r'\D'), '');
    return d.isEmpty ? null : d;
  }

  bool _ehCep(String? digits) => digits != null && digits.length == 8;

  bool _ehTelefone(String? digits) {
    if (digits == null) return false;
    return digits.length == 10 || digits.length == 11;
  }

  bool _vazio(String? valor) => valor == null || valor.trim().isEmpty;

  // E3: calcula e armazena a qualidade da extração.
  void _calcularQualidade() {
    final camposBasicos = [
      _dados['nome'],
      _dados['email'],
      _dados['telefone'],
      _dados['cpf'],
      _dados['dataNascimento'],
      _dados['logradouro'],
      _dados['numero'],
      _dados['bairro'],
      _dados['cidade'],
      _dados['estado'],
      _dados['cep'],
      _dados['resumo'],
    ];
    _camposPreenchidos =
        camposBasicos.where((c) => c != null && c.toString().isNotEmpty).length;
    if (_origemExtracao.isEmpty) {
      _origemExtracao = 'regex (fallback)';
    }
  }

  // E3: widget indicador de qualidade exibido acima dos campos.
  Widget _buildIndicadorQualidade() {
    if (_origemExtracao.isEmpty) return const SizedBox.shrink();
    final preenchidos = _camposPreenchidos;
    const total = _totalCampos;
    final Color cor = preenchidos >= 8
        ? Colors.green
        : preenchidos >= 5
            ? Colors.orange
            : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$preenchidos de $total campos preenchidos automaticamente',
            style: TextStyle(color: cor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Fonte: $_origemExtracao',
            style:
                const TextStyle(color: AppCores.textoSecundario, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    String v(String chave) {
      final edit = _editaveis[chave]?.text;
      if (edit != null) return edit;
      final extra = _dados[chave];
      return extra is String ? extra : '';
    }

    final resumo = v('resumo').trim();
    final habilidades = _listaStrings('habilidades');
    if (resumo.isEmpty || habilidades.isEmpty) {
      _mostrarAvisoMinimos();
      return;
    }

    setState(() => _salvando = true);
    final prefs = await SharedPreferences.getInstance();
    // E1: usar UID string (Firebase Auth) em vez de id inteiro legado.
    final uid = prefs.getString('usuario_uid');
    final agora = DateTime.now().toIso8601String();

    _corrigirTelefoneCepDados();

    String? vLimpo(String chave) {
      final valor = v(chave).trim();
      if (valor.isEmpty) return null;
      if (_campoInvalido(chave, valor)) return null;
      if (chave == 'telefone') return Validadores.normalizarTelefone(valor);
      if (chave == 'cep') return Validadores.normalizarCep(valor);
      return valor;
    }

    final experiencias = _listaMap('experiencias');
    final formacoes = _listaMap('formacoes');
    final idiomas = _listaIdiomas();

    final candidato = Candidato(
      usuarioUid: uid,
      nome: v('nome').isNotEmpty ? v('nome') : 'Sem nome',
      cpf: vLimpo('cpf'),
      email: vLimpo('email'),
      telefone: vLimpo('telefone'),
      dataNascimento:
          v('dataNascimento').isNotEmpty ? v('dataNascimento') : null,
      logradouro: v('logradouro').isNotEmpty ? v('logradouro') : null,
      numero: v('numero').isNotEmpty ? v('numero') : null,
      bairro: v('bairro').isNotEmpty ? v('bairro') : null,
      cidade: v('cidade').isNotEmpty ? v('cidade') : null,
      estado: v('estado').isNotEmpty ? v('estado') : null,
      cep: vLimpo('cep'),
      resumo: resumo,
      criadoEm: agora,
      atualizadoEm: agora,
    );

    final existente = await getIt<VerificarDuplicidade>().executar(
      cpf: candidato.cpf,
      email: candidato.email,
    );

    if (!mounted) return;
    setState(() => _salvando = false);

    if (existente != null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Candidato já cadastrado'),
          content: Text(
            'Já existe um cadastro com este CPF/e-mail.\n'
            'Nome: ${existente.nome}\n\n'
            'O que deseja fazer?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await getIt<MergeCandidato>().executar(
                  existente,
                  candidato,
                  experiencias: experiencias,
                  formacoes: formacoes,
                  habilidades: habilidades,
                  idiomas: idiomas,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados atualizados com sucesso'),
                      backgroundColor: AppCores.primaria,
                    ),
                  );
                  Navigator.of(context).pop();
                }
                await getIt<RankingRepositorioFirestore>()
                    .apagarPorCandidato(existente.idStr!);
              },
              child: const Text(
                'Atualizar dados existentes',
                style: TextStyle(color: AppCores.primaria),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppCores.cta),
              onPressed: () async {
                Navigator.pop(context);
                final repo = getIt<ICandidatoRepositorio>();
                try {
                  await repo.salvarCompleto(
                    candidato,
                    experiencias: experiencias,
                    formacoes: formacoes,
                    habilidades: habilidades,
                    idiomas: idiomas,
                    // E4: registrar qualidade da extração.
                    camposPreenchidos: _camposPreenchidos,
                    totalCampos: _totalCampos,
                    origemExtracao: _origemExtracao,
                  );
                } catch (_) {
                  await repo.salvar(candidato);
                }
                // Q3 — Auditoria: registra upload de currículo (novo).
                if (uid != null) {
                  getIt<AuditoriaService>().registrar(
                    uid: uid,
                    acao: 'upload_curriculo',
                    detalhes: candidato.nome,
                  );
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Candidato cadastrado como novo'),
                      backgroundColor: AppCores.primaria,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Cadastrar como novo',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      final repo = getIt<ICandidatoRepositorio>();
      try {
        await repo.salvarCompleto(
          candidato,
          experiencias: experiencias,
          formacoes: formacoes,
          habilidades: habilidades,
          idiomas: idiomas,
          // E4: registrar qualidade da extração.
          camposPreenchidos: _camposPreenchidos,
          totalCampos: _totalCampos,
          origemExtracao: _origemExtracao,
        );
      } catch (_) {
        await repo.salvar(candidato);
      }
      // Q3 — Auditoria: registra upload de currículo (candidato existente).
      if (uid != null) {
        getIt<AuditoriaService>().registrar(
          uid: uid,
          acao: 'upload_curriculo',
          detalhes: candidato.nome,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.curriculoSalvo),
          backgroundColor: AppCores.primaria,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: const RhosAppBarInterna(
        icone: Icons.upload_file,
        titulo: AppStrings.tituloUpload,
      ),
      body: switch (_estado) {
        _Estado.inicial => _buildInicial(),
        _Estado.carregando => _buildCarregando(),
        _Estado.resultado => _buildResultado(),
      },
    );
  }

  Widget _buildInicial() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description_outlined,
                  size: 80, color: AppCores.textoSecundario),
              const SizedBox(height: 16),
              const Text(AppStrings.selecioneCurriculo,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(AppStrings.formatosAceitos,
                  style:
                      TextStyle(fontSize: 14, color: AppCores.textoSecundario)),
              const SizedBox(height: 32),
              BotaoCta(
                  label: AppStrings.selecionarArquivo,
                  aoPresionar: _selecionar),
            ],
          ),
        ),
      );

  Widget _buildCarregando() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LinearProgressIndicator(color: AppCores.primaria),
              const SizedBox(height: 24),
              Text(_mensagemCarregando,
                  style: const TextStyle(
                      fontSize: 14, color: AppCores.textoSecundario)),
            ],
          ),
        ),
      );

  Widget _buildResultado() => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // E3: indicador de qualidade da extração.
                _buildIndicadorQualidade(),
                ..._campos.map((campo) {
                  final chave = campo.$1;
                  final label = campo.$2;
                  final controller = _editaveis[chave];
                  final texto = controller?.text ?? '';
                  final ok = texto.isNotEmpty && !_campoInvalido(chave, texto);
                  return ListTile(
                    leading: Icon(
                      ok ? Icons.check_circle : Icons.warning_amber,
                      color: ok ? Colors.green : AppCores.cta,
                    ),
                    title: Text(label,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: TextField(
                      controller: controller,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(hintText: 'Informe $label'),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                _buildSecaoTitulo('Experiências profissionais'),
                ..._buildExperiencias(),
                const SizedBox(height: 12),
                _buildSecaoTitulo('Formações'),
                ..._buildFormacoes(),
                const SizedBox(height: 12),
                _buildSecaoTitulo('Habilidades'),
                _buildHabilidades(),
                const SizedBox(height: 12),
                _buildSecaoTitulo('Idiomas'),
                _buildIdiomas(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: BotaoCta(
              label: AppStrings.confirmarSalvar,
              carregando: _salvando,
              aoPresionar: _salvar,
            ),
          ),
        ],
      );

  Widget _buildSecaoTitulo(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppCores.primaria,
          ),
        ),
      );

  List<Widget> _buildExperiencias() {
    final lista = _listaMap('experiencias');
    final widgets = <Widget>[];

    if (lista.isEmpty) {
      widgets.add(_buildTextoVazio('Nenhuma experiência encontrada'));
    } else {
      for (var i = 0; i < lista.length; i++) {
        final exp = lista[i];
        final cargo = _texto(exp['cargo']);
        final empresa = _texto(exp['empresa']);
        final inicio = _texto(exp['dataInicio']);
        final fim = _texto(exp['dataFim']);
        final atual = exp['atual'] == true;
        final periodo = _periodo(inicio, fim, atual);

        widgets.add(ListTile(
          leading:
              const Icon(Icons.work_outline, color: AppCores.textoSecundario),
          title: Text(cargo.isNotEmpty ? cargo : 'Experiência'),
          subtitle: Text(
            [empresa, periodo].where((t) => t.isNotEmpty).join(' · '),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon:
                    const Icon(Icons.edit, color: AppCores.primaria, size: 20),
                onPressed: () => _editarExperiencia(i),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppCores.cta, size: 20),
                onPressed: () => _removerItem('experiencias', i),
              ),
            ],
          ),
        ));
      }
    }

    widgets.add(
        _botaoAdicionar('Adicionar experiência', () => _editarExperiencia()));
    return widgets;
  }

  List<Widget> _buildFormacoes() {
    final lista = _listaMap('formacoes');
    final widgets = <Widget>[];

    if (lista.isEmpty) {
      widgets.add(_buildTextoVazio('Nenhuma formação encontrada'));
    } else {
      for (var i = 0; i < lista.length; i++) {
        final f = lista[i];
        final instituicao = _texto(f['instituicao']);
        final curso = _texto(f['curso']);
        final nivel = _texto(f['nivel']);
        final inicio = _texto(f['dataInicio']);
        final fim = _texto(f['dataFim']);
        final emAndamento = f['emAndamento'] == true;
        final periodo = _periodo(inicio, fim, emAndamento);

        widgets.add(ListTile(
          leading: const Icon(Icons.school_outlined,
              color: AppCores.textoSecundario),
          title: Text(curso.isNotEmpty ? curso : 'Formação'),
          subtitle: Text(
            [instituicao, nivel, periodo]
                .where((t) => t.isNotEmpty)
                .join(' · '),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon:
                    const Icon(Icons.edit, color: AppCores.primaria, size: 20),
                onPressed: () => _editarFormacao(i),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppCores.cta, size: 20),
                onPressed: () => _removerItem('formacoes', i),
              ),
            ],
          ),
        ));
      }
    }

    widgets.add(_botaoAdicionar('Adicionar formação', () => _editarFormacao()));
    return widgets;
  }

  Widget _buildHabilidades() {
    final itens = _listaStrings('habilidades');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (itens.isEmpty)
          _buildTextoVazio('Nenhuma habilidade encontrada')
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: itens
                  .map((h) => InputChip(
                        label: Text(h),
                        backgroundColor: AppCores.fundoInput,
                        onDeleted: () => _removerHabilidade(h),
                      ))
                  .toList(),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _habilidadeCtrl,
                decoration: const InputDecoration(
                    hintText: 'Adicionar habilidade (ex: Flutter)'),
              ),
            ),
            IconButton(
              onPressed: _adicionarHabilidade,
              icon: const Icon(Icons.add_circle, color: AppCores.primaria),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdiomas() {
    final lista = _listaIdiomas();
    final widgets = <Widget>[];

    if (lista.isEmpty) {
      widgets.add(_buildTextoVazio('Nenhum idioma encontrado'));
    } else {
      for (var i = 0; i < lista.length; i++) {
        final idioma = lista[i];
        final nome = _texto(idioma['nome']);
        final nivel = _texto(idioma['nivel']);
        final label = nivel.isNotEmpty ? '$nome — $nivel' : nome;

        widgets.add(ListTile(
          leading: const Icon(Icons.language, color: AppCores.textoSecundario),
          title: Text(label.isNotEmpty ? label : 'Idioma'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon:
                    const Icon(Icons.edit, color: AppCores.primaria, size: 20),
                onPressed: () => _editarIdioma(i),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppCores.cta, size: 20),
                onPressed: () => _removerItem('idiomas', i),
              ),
            ],
          ),
        ));
      }
    }

    widgets.add(_botaoAdicionar('Adicionar idioma', () => _editarIdioma()));
    return Column(children: widgets);
  }

  Widget _buildTextoVazio(String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(texto,
            style: const TextStyle(color: AppCores.textoSecundario)),
      );

  String _texto(dynamic valor) => valor == null ? '' : valor.toString().trim();

  String _periodo(String inicio, String fim, bool atual) {
    if (inicio.isEmpty && fim.isEmpty) return '';
    if (atual || fim.isEmpty) {
      return '${inicio.isNotEmpty ? inicio : '?'} - atual';
    }
    return '${inicio.isNotEmpty ? inicio : '?'} - $fim';
  }

  Widget _botaoAdicionar(String texto, VoidCallback onPressed) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add, color: AppCores.primaria),
          label: Text(texto, style: const TextStyle(color: AppCores.primaria)),
        ),
      );

  List<Map<String, dynamic>> _listaMap(String chave) {
    final raw = _dados[chave];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<String> _listaStrings(String chave) {
    final raw = _dados[chave];
    if (raw is! List) return <String>[];
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _listaIdiomas() {
    final raw = _dados['idiomas'];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          if (e is String) return {'nome': e.trim(), 'nivel': 'basico'};
          return <String, dynamic>{};
        })
        .where((m) => _texto(m['nome']).isNotEmpty)
        .toList();
  }

  void _removerItem(String chave, int index) {
    final lista = chave == 'idiomas' ? _listaIdiomas() : _listaMap(chave);
    if (index < 0 || index >= lista.length) return;
    lista.removeAt(index);
    setState(() => _dados[chave] = lista);
  }

  Future<void> _editarExperiencia([int? index]) async {
    final lista = _listaMap('experiencias');
    final atual = index != null && index < lista.length ? lista[index] : {};

    final cargoCtrl = TextEditingController(text: _texto(atual['cargo']));
    final empresaCtrl = TextEditingController(text: _texto(atual['empresa']));
    final inicioCtrl = TextEditingController(text: _texto(atual['dataInicio']));
    final fimCtrl = TextEditingController(text: _texto(atual['dataFim']));
    final descCtrl = TextEditingController(text: _texto(atual['descricao']));
    var atualFlag = atual['atual'] == true;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Experiência profissional'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cargoCtrl,
                  decoration: const InputDecoration(labelText: 'Cargo'),
                ),
                TextField(
                  controller: empresaCtrl,
                  decoration: const InputDecoration(labelText: 'Empresa'),
                ),
                TextField(
                  controller: inicioCtrl,
                  decoration: const InputDecoration(labelText: 'Data início'),
                ),
                TextField(
                  controller: fimCtrl,
                  decoration: const InputDecoration(labelText: 'Data fim'),
                ),
                SwitchListTile(
                  value: atualFlag,
                  title: const Text('Trabalho atual'),
                  onChanged: (v) => setDialogState(() => atualFlag = v),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final novo = <String, dynamic>{
                  'cargo': cargoCtrl.text.trim(),
                  'empresa': empresaCtrl.text.trim(),
                  'dataInicio': inicioCtrl.text.trim(),
                  'dataFim': atualFlag ? '' : fimCtrl.text.trim(),
                  'atual': atualFlag,
                  'descricao': descCtrl.text.trim(),
                };
                Navigator.pop(context, novo);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    cargoCtrl.dispose();
    empresaCtrl.dispose();
    inicioCtrl.dispose();
    fimCtrl.dispose();
    descCtrl.dispose();

    if (resultado == null) return;
    if (_texto(resultado['cargo']).isEmpty &&
        _texto(resultado['empresa']).isEmpty) {
      return;
    }

    if (index != null && index < lista.length) {
      lista[index] = resultado;
    } else {
      lista.add(resultado);
    }
    setState(() => _dados['experiencias'] = lista);
  }

  Future<void> _editarFormacao([int? index]) async {
    final lista = _listaMap('formacoes');
    final atual = index != null && index < lista.length ? lista[index] : {};

    final instituicaoCtrl =
        TextEditingController(text: _texto(atual['instituicao']));
    final cursoCtrl = TextEditingController(text: _texto(atual['curso']));
    final nivelCtrl = TextEditingController(text: _texto(atual['nivel']));
    final inicioCtrl = TextEditingController(text: _texto(atual['dataInicio']));
    final fimCtrl = TextEditingController(text: _texto(atual['dataFim']));
    var emAndamento = atual['emAndamento'] == true;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Formação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: instituicaoCtrl,
                  decoration: const InputDecoration(labelText: 'Instituição'),
                ),
                TextField(
                  controller: cursoCtrl,
                  decoration: const InputDecoration(labelText: 'Curso'),
                ),
                TextField(
                  controller: nivelCtrl,
                  decoration: const InputDecoration(labelText: 'Nível'),
                ),
                TextField(
                  controller: inicioCtrl,
                  decoration: const InputDecoration(labelText: 'Data início'),
                ),
                TextField(
                  controller: fimCtrl,
                  decoration: const InputDecoration(labelText: 'Data fim'),
                ),
                SwitchListTile(
                  value: emAndamento,
                  title: const Text('Em andamento'),
                  onChanged: (v) => setDialogState(() => emAndamento = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final novo = <String, dynamic>{
                  'instituicao': instituicaoCtrl.text.trim(),
                  'curso': cursoCtrl.text.trim(),
                  'nivel': nivelCtrl.text.trim(),
                  'dataInicio': inicioCtrl.text.trim(),
                  'dataFim': emAndamento ? '' : fimCtrl.text.trim(),
                  'emAndamento': emAndamento,
                };
                Navigator.pop(context, novo);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    instituicaoCtrl.dispose();
    cursoCtrl.dispose();
    nivelCtrl.dispose();
    inicioCtrl.dispose();
    fimCtrl.dispose();

    if (resultado == null) return;
    if (_texto(resultado['instituicao']).isEmpty &&
        _texto(resultado['curso']).isEmpty) {
      return;
    }

    if (index != null && index < lista.length) {
      lista[index] = resultado;
    } else {
      lista.add(resultado);
    }
    setState(() => _dados['formacoes'] = lista);
  }

  Future<void> _editarIdioma([int? index]) async {
    final lista = _listaIdiomas();
    final atual = index != null && index < lista.length ? lista[index] : {};

    final nomeCtrl = TextEditingController(text: _texto(atual['nome']));
    final nivelCtrl = TextEditingController(text: _texto(atual['nivel']));

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Idioma'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Idioma'),
              ),
              TextField(
                controller: nivelCtrl,
                decoration: const InputDecoration(labelText: 'Nível'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final novo = <String, dynamic>{
                'nome': nomeCtrl.text.trim(),
                'nivel': nivelCtrl.text.trim(),
              };
              Navigator.pop(context, novo);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    nomeCtrl.dispose();
    nivelCtrl.dispose();

    if (resultado == null) return;
    if (_texto(resultado['nome']).isEmpty) return;

    if (index != null && index < lista.length) {
      lista[index] = resultado;
    } else {
      lista.add(resultado);
    }
    setState(() => _dados['idiomas'] = lista);
  }

  void _adicionarHabilidade() {
    final texto = _habilidadeCtrl.text.trim();
    if (texto.isEmpty) return;
    final itens = texto
        .split(RegExp(r'[,;\n\|/]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (itens.isEmpty) return;

    final lista = _listaStrings('habilidades');
    for (final item in itens) {
      if (!lista.contains(item)) lista.add(item);
    }
    _habilidadeCtrl.clear();
    setState(() => _dados['habilidades'] = lista);
  }

  void _removerHabilidade(String habilidade) {
    final lista = _listaStrings('habilidades');
    lista.removeWhere((h) => h == habilidade);
    setState(() => _dados['habilidades'] = lista);
  }
}
