import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rh_os/core/constantes/app_rotas.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/tema/app_estilos.dart';
import 'package:rh_os/core/utils/validadores.dart';
import 'package:rh_os/data/repositorios/ranking_repositorio_firestore.dart';
import 'package:rh_os/domain/entidades/experiencia.dart';
import 'package:rh_os/domain/entidades/formacao.dart';
import 'package:rh_os/domain/entidades/habilidade.dart';
import 'package:rh_os/domain/entidades/idioma.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/presentation/widgets/campo_perfil_tile.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaInformacoesPerfil extends ConsumerStatefulWidget {
  const TelaInformacoesPerfil({super.key});

  @override
  ConsumerState<TelaInformacoesPerfil> createState() =>
      _TelaInformacoesPerfilState();
}

class _TelaInformacoesPerfilState extends ConsumerState<TelaInformacoesPerfil> {
  Candidato? _candidato;
  bool _carregando = true;
  bool _salvandoListas = false;
  bool _semCurriculo = false;
  List<Map<String, dynamic>> _experiencias = [];
  List<Map<String, dynamic>> _formacoes = [];
  List<String> _habilidades = [];
  List<Map<String, dynamic>> _idiomas = [];
  final TextEditingController _habilidadeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _habilidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('usuario_uid');
    if (uid == null) {
      if (mounted) setState(() => _carregando = false);
      return;
    }

    final repo = getIt<ICandidatoRepositorio>();
    Candidato? candidato;
    bool semCurriculo = false;

    // Busca primaria por UID
    candidato = await repo.buscarPorUsuarioUid(uid);

    if (candidato == null) {
      // Fallback: busca por e-mail
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email != null) {
        candidato = await repo.buscarPorEmail(email);
      }

      // Se achou por email e usuario_uid esta vazio: vincular para proximas buscas
      if (candidato != null &&
          candidato.idStr != null &&
          (candidato.usuarioUid == null || candidato.usuarioUid!.isEmpty)) {
        await repo.atualizarCampoStr(candidato.idStr!, 'usuario_uid', uid);
        debugPrint('[Perfil] usuario_uid vinculado no Firestore');
      }
    }

    if (candidato == null) semCurriculo = true;

    if (candidato?.idStr != null) {
      final idStr = candidato!.idStr!;
      final results = await Future.wait([
        repo.listarExperienciasStr(idStr),
        repo.listarFormacoesStr(idStr),
        repo.listarHabilidadesStr(idStr),
        repo.listarIdiomasStr(idStr),
      ]);

      _experiencias = (results[0] as List<Experiencia>).map(_expToMap).toList();
      _formacoes = (results[1] as List<Formacao>).map(_formToMap).toList();
      _habilidades = (results[2] as List<Habilidade>)
          .map((h) => h.nome)
          .where((n) => n.trim().isNotEmpty)
          .toList();
      _idiomas = (results[3] as List<Idioma>).map(_idiomaToMap).toList();
    }

    if (mounted) {
      setState(() {
        _candidato = candidato;
        _semCurriculo = semCurriculo;
        _carregando = false;
      });
    }
  }

  Future<void> _irEditar(String campo, String label, String valor) async {
    await context.push(AppRotas.editarCampo,
        extra: {'campo': campo, 'label': label, 'valorAtual': valor});
    if (mounted) await _carregar();
  }

  Map<String, dynamic> _expToMap(Experiencia e) => {
        'cargo': e.cargo,
        'empresa': e.empresa,
        'descricao': e.descricao,
        'dataInicio': e.dataInicio,
        'dataFim': e.dataFim ?? '',
        'atual': e.atual,
      };

  Map<String, dynamic> _formToMap(Formacao f) => {
        'instituicao': f.instituicao,
        'curso': f.curso,
        'nivel': f.nivel,
        'dataInicio': f.dataInicio,
        'dataFim': f.dataFim ?? '',
        'emAndamento': f.emAndamento,
      };

  Map<String, dynamic> _idiomaToMap(Idioma i) => {
        'nome': i.nome,
        'nivel': i.nivel,
      };

  bool _validarMinimos() {
    final resumo = _candidato?.resumo?.trim() ?? '';
    if (resumo.isEmpty || _habilidades.isEmpty) {
      _mostrarAvisoMinimos();
      return false;
    }
    return true;
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

  Future<void> _salvarListas() async {
    if (_candidato?.idStr == null) return;
    if (!_validarMinimos()) return;
    final repo = getIt<ICandidatoRepositorio>();

    setState(() => _salvandoListas = true);
    try {
      await repo.salvarCompleto(
        _candidato!,
        experiencias: _experiencias,
        formacoes: _formacoes,
        habilidades: _habilidades,
        idiomas: _idiomas,
      );
      await getIt<RankingRepositorioFirestore>()
          .apagarPorCandidato(_candidato!.idStr!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar alterações'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvandoListas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _candidato;
    final telefoneFmt = Validadores.normalizarTelefone(c?.telefone);
    final cepFmt = Validadores.normalizarCep(c?.cep);
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: const RhosAppBarInterna(
        icone: Icons.person_outline,
        titulo: AppStrings.tituloPerfil,
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppCores.primaria))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_semCurriculo)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'Nenhum currículo vinculado a esta conta.\n'
                        'Registre um currículo para preencher seu perfil.',
                        style: TextStyle(color: AppCores.textoSecundario),
                      ),
                    ),
                  const _Secao(titulo: 'Resumo profissional'),
                  CampoPerfilTile(
                    icone: Icons.article_outlined,
                    valor: c?.resumo ?? '',
                    label: 'Resumo',
                    aoTap: () => _irEditar('resumo', 'Resumo', c?.resumo ?? ''),
                  ),
                  const _Secao(titulo: AppStrings.infoPessoal),
                  CampoPerfilTile(
                    icone: Icons.person,
                    valor: c?.nome ?? '',
                    label: AppStrings.labelNome,
                    aoTap: () => _irEditar(
                        'nome_completo', AppStrings.labelNome, c?.nome ?? ''),
                  ),
                  CampoPerfilTile(
                    icone: Icons.badge,
                    valor: c?.cpf ?? '',
                    label: AppStrings.labelCpf,
                    aoTap: () =>
                        _irEditar('cpf', AppStrings.labelCpf, c?.cpf ?? ''),
                  ),
                  CampoPerfilTile(
                    icone: Icons.edit,
                    valor: c?.nome ?? '',
                    label: AppStrings.labelNomePreferencia,
                    aoTap: () => _irEditar('nome_preferencia',
                        AppStrings.labelNomePreferencia, c?.nome ?? ''),
                  ),
                  const _Secao(titulo: AppStrings.dadosConta),
                  CampoPerfilTile(
                    icone: Icons.email,
                    valor: c?.email ?? '',
                    label: AppStrings.labelEmail,
                    aoTap: () => _irEditar(
                        'email', AppStrings.labelEmail, c?.email ?? ''),
                  ),
                  CampoPerfilTile(
                    icone: Icons.phone,
                    valor: telefoneFmt ?? '',
                    label: AppStrings.labelTelefone,
                    aoTap: () => _irEditar('telefone', AppStrings.labelTelefone,
                        c?.telefone ?? ''),
                  ),
                  const _Secao(titulo: AppStrings.endereco),
                  CampoPerfilTile(
                    icone: Icons.home,
                    valor: [c?.logradouro, c?.numero]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(', '),
                    label: AppStrings.labelRua,
                    aoTap: () => _irEditar(
                        'rua',
                        AppStrings.labelRua,
                        [c?.logradouro, c?.numero]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(', ')),
                  ),
                  CampoPerfilTile(
                    icone: Icons.location_city,
                    valor: c?.bairro ?? '',
                    label: AppStrings.labelBairro,
                    aoTap: () => _irEditar(
                        'bairro', AppStrings.labelBairro, c?.bairro ?? ''),
                  ),
                  CampoPerfilTile(
                    icone: Icons.map,
                    valor: [c?.cidade, c?.estado]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(' - '),
                    label: AppStrings.labelCidade,
                    aoTap: () => _irEditar(
                        'cidade',
                        AppStrings.labelCidade,
                        [c?.cidade, c?.estado]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' - ')),
                  ),
                  CampoPerfilTile(
                    icone: Icons.pin_drop,
                    valor: cepFmt ?? '',
                    label: AppStrings.labelCep,
                    aoTap: () =>
                        _irEditar('cep', AppStrings.labelCep, c?.cep ?? ''),
                  ),
                  if (_salvandoListas)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: LinearProgressIndicator(color: AppCores.primaria),
                    ),
                  const _Secao(titulo: 'Experiências profissionais'),
                  ..._buildExperiencias(),
                  const _Secao(titulo: 'Formações'),
                  ..._buildFormacoes(),
                  const _Secao(titulo: 'Habilidades'),
                  _buildHabilidades(),
                  const _Secao(titulo: 'Idiomas'),
                  _buildIdiomas(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildExperiencias() {
    final widgets = <Widget>[];

    if (_experiencias.isEmpty) {
      widgets.add(_buildTextoVazio('Nenhuma experiência encontrada'));
    } else {
      for (var i = 0; i < _experiencias.length; i++) {
        final exp = _experiencias[i];
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
    final widgets = <Widget>[];

    if (_formacoes.isEmpty) {
      widgets.add(_buildTextoVazio('Nenhuma formação encontrada'));
    } else {
      for (var i = 0; i < _formacoes.length; i++) {
        final f = _formacoes[i];
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_habilidades.isEmpty)
          _buildTextoVazio('Nenhuma habilidade encontrada')
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _habilidades
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
                  hintText: 'Adicionar habilidade (ex: Flutter)',
                ),
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
    final widgets = <Widget>[];

    if (_idiomas.isEmpty) {
      widgets.add(_buildTextoVazio('Nenhum idioma encontrado'));
    } else {
      for (var i = 0; i < _idiomas.length; i++) {
        final idioma = _idiomas[i];
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(texto,
            style: const TextStyle(color: AppCores.textoSecundario)),
      );

  Widget _botaoAdicionar(String texto, VoidCallback onPressed) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add, color: AppCores.primaria),
          label: Text(texto, style: const TextStyle(color: AppCores.primaria)),
        ),
      );

  String _texto(dynamic valor) => valor == null ? '' : valor.toString().trim();

  String _periodo(String inicio, String fim, bool atual) {
    if (inicio.isEmpty && fim.isEmpty) return '';
    if (atual || fim.isEmpty) {
      return '${inicio.isNotEmpty ? inicio : '?'} - atual';
    }
    return '${inicio.isNotEmpty ? inicio : '?'} - $fim';
  }

  void _removerItem(String chave, int index) {
    setState(() {
      if (chave == 'experiencias' && index < _experiencias.length) {
        _experiencias.removeAt(index);
      } else if (chave == 'formacoes' && index < _formacoes.length) {
        _formacoes.removeAt(index);
      } else if (chave == 'idiomas' && index < _idiomas.length) {
        _idiomas.removeAt(index);
      }
    });
    _salvarListas();
  }

  Future<void> _editarExperiencia([int? index]) async {
    final atual = (index != null && index < _experiencias.length)
        ? _experiencias[index]
        : <String, dynamic>{};

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

    setState(() {
      if (index != null && index < _experiencias.length) {
        _experiencias[index] = resultado;
      } else {
        _experiencias.add(resultado);
      }
    });
    _salvarListas();
  }

  Future<void> _editarFormacao([int? index]) async {
    final atual = (index != null && index < _formacoes.length)
        ? _formacoes[index]
        : <String, dynamic>{};

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

    setState(() {
      if (index != null && index < _formacoes.length) {
        _formacoes[index] = resultado;
      } else {
        _formacoes.add(resultado);
      }
    });
    _salvarListas();
  }

  Future<void> _editarIdioma([int? index]) async {
    final atual = (index != null && index < _idiomas.length)
        ? _idiomas[index]
        : <String, dynamic>{};

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

    setState(() {
      if (index != null && index < _idiomas.length) {
        _idiomas[index] = resultado;
      } else {
        _idiomas.add(resultado);
      }
    });
    _salvarListas();
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

    setState(() {
      for (final item in itens) {
        if (!_habilidades.contains(item)) _habilidades.add(item);
      }
      _habilidadeCtrl.clear();
    });
    _salvarListas();
  }

  void _removerHabilidade(String habilidade) {
    if (_habilidades.length <= 1) {
      _mostrarAvisoMinimos();
      return;
    }
    setState(() => _habilidades.removeWhere((h) => h == habilidade));
    _salvarListas();
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(titulo, style: AppEstilos.headerSecao),
    );
  }
}
