import 'package:rh_os/core/constantes/ranking_config.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/entidades/candidatura.dart';
import 'package:rh_os/domain/entidades/experiencia.dart';
import 'package:rh_os/domain/entidades/formacao.dart';
import 'package:rh_os/domain/entidades/habilidade.dart';
import 'package:rh_os/domain/entidades/idioma.dart';
import 'package:rh_os/domain/entidades/vaga.dart';

class RanquearCandidatos {
  static const _idiomasConhecidos = [
    'ingles',
    'english',
    'espanhol',
    'spanish',
    'frances',
    'french',
    'alemao',
    'german',
    'italiano',
    'italian',
    'mandarim',
    'chines',
    'japones',
    'portugues',
  ];

  static const _softSkillsConhecidos = [
    'comunicacao',
    'lideranca',
    'trabalho em equipe',
    'organizacao',
    'proatividade',
    'aprendizado rapido',
    'resolucao de problemas',
    'colaboracao',
    'adaptabilidade',
  ];

  static const _tiCursos = [
    'ciencia da computacao',
    'ciencias da computacao',
    'engenharia de software',
    'sistemas de informacao',
    'analise e desenvolvimento de sistemas',
    'ads',
    'tecnologia da informacao',
    'informatica',
  ];

  static const _tiKeywords = [
    'programacao',
    'desenvolvimento',
    'software',
    'flutter',
    'dart',
    'java',
    'c#',
    'csharp',
    '.net',
    'dotnet',
    'sql',
    'banco de dados',
    'javascript',
    'react',
    'git',
    'angular',
    'kotlin',
    'python',
  ];

  static const _skillAliases = {
    'csharp': 'c#',
    'c-sharp': 'c#',
    'dotnet': '.net',
    'asp.net': '.net',
    'banco de dados': 'sql',
    'bd': 'sql',
  };

  static const _nivelFormacaoOrdem = [
    'ensino medio',
    'tecnico',
    'tecnologo',
    'graduacao',
    'bacharelado',
    'licenciatura',
    'pos-graduacao',
    'especializacao',
    'mba',
    'mestrado',
    'doutorado',
  ];

  double calcularScore(
    Candidato candidato,
    Vaga vaga, {
    List<Habilidade> habilidades = const [],
    List<Idioma> idiomas = const [],
    List<Experiencia> experiencias = const [],
    List<Formacao> formacoes = const [],
  }) {
    final detalhado = calcularDetalhado(
      candidato,
      vaga,
      habilidades: habilidades,
      idiomas: idiomas,
      experiencias: experiencias,
      formacoes: formacoes,
    );
    return detalhado.scoreTotal;
  }

  RankingDetalhado calcularDetalhado(
    Candidato candidato,
    Vaga vaga, {
    List<Habilidade> habilidades = const [],
    List<Idioma> idiomas = const [],
    List<Experiencia> experiencias = const [],
    List<Formacao> formacoes = const [],
  }) {
    final resumo = _normalizar(candidato.resumo ?? '');
    final vagaTexto = _normalizar(
      '${vaga.titulo} ${vaga.descricao} ${vaga.requisitos ?? ''} '
      '${vaga.habilidades?.join(' ') ?? ''} ${vaga.softSkills?.join(' ') ?? ''}',
    );

    final hardScore = _scoreHardSkills(
      resumo,
      vaga,
      habilidades: habilidades,
    );
    final softScore = _scoreSoftSkills(
      resumo,
      vaga,
    );
    final expScore = _scoreExperiencia(
      resumo,
      vagaTexto,
      experiencias,
    );
    final formScore = _scoreFormacao(
      resumo,
      vagaTexto,
      formacoes,
    );
    final idiomaScore = _scoreIdiomas(
      resumo,
      vagaTexto,
      idiomas,
    );

    final scores = <String, double>{
      'hard_skills': hardScore,
      'soft_skills': softScore,
      'experiencia': expScore,
      'formacao': formScore,
      'idiomas': idiomaScore,
    };

    final total = _calcularTotal(scores);

    final requisitos = _extrairRequisitosObrigatorios(vaga);
    final faltantes = _faltandoRequisitos(resumo, habilidades, requisitos);
    final gatingAprovado = faltantes.isEmpty;
    final scoreFinal = gatingAprovado ? total : (total * 0.2);

    return RankingDetalhado(
      scoreTotal: double.parse(scoreFinal.toStringAsFixed(1)),
      scoresPorEixo: scores,
      gatingAprovado: gatingAprovado,
      requisitosNaoAtendidos: faltantes,
    );
  }

  // Ordena candidaturas por score e data.
  List<Candidatura> ranquear(
    List<Candidatura> candidaturas,
    List<Candidato> candidatos,
    Vaga vaga,
  ) {
    final mapaCandidatos = {for (final c in candidatos) c.id: c};
    final mapaCandidatosStr = {
      for (final c in candidatos)
        if (c.idStr != null) c.idStr!: c
    };

    final comScore = candidaturas.map((candidatura) {
      final candidato = candidatura.candidatoIdStr != null
          ? mapaCandidatosStr[candidatura.candidatoIdStr]
          : mapaCandidatos[candidatura.candidatoId];
      final score = candidato != null ? calcularScore(candidato, vaga) : 0.0;
      return _CandidaturaComScore(candidatura, score);
    }).toList();

    comScore.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return b.candidatura.dataCandidatura
          .compareTo(a.candidatura.dataCandidatura);
    });

    return comScore.map((cs) => cs.candidatura).toList();
  }

  double _scoreHardSkills(
    String resumo,
    Vaga vaga, {
    List<Habilidade> habilidades = const [],
  }) {
    final requeridas = _requisitosHardSkills(vaga);
    if (requeridas.isEmpty) {
      return habilidades.isNotEmpty || resumo.isNotEmpty ? 2.0 : 0.0;
    }

    final candSkills = <String>{
      for (final h in habilidades) _normalizarSkill(h.nome),
    };

    var encontrados = 0;
    for (final req in requeridas) {
      if (candSkills.contains(req) || resumo.contains(req)) {
        encontrados++;
      }
    }

    final ratio = encontrados / requeridas.length;
    return _ratioToScore(ratio);
  }

  double _scoreSoftSkills(String resumo, Vaga vaga) {
    final requeridas = (vaga.softSkills ?? [])
        .map(_normalizarSkill)
        .where((s) => s.isNotEmpty)
        .toList();

    final encontrados = _softSkillsConhecidos
        .where((s) => resumo.contains(_normalizar(s)))
        .length;

    if (requeridas.isEmpty) {
      return encontrados > 0 ? 2.0 : 0.0;
    }

    var match = 0;
    for (final s in requeridas) {
      if (resumo.contains(s)) match++;
    }

    final ratio = match / requeridas.length;
    return _ratioToScore(ratio);
  }

  double _scoreExperiencia(
    String resumo,
    String vagaTexto,
    List<Experiencia> experiencias,
  ) {
    if (experiencias.isEmpty) {
      return resumo.contains('experiencia') ? 2.0 : 0.0;
    }

    final keywords = _extrairKeywordsVaga(vagaTexto);
    var relevantes = 0;
    for (final e in experiencias) {
      final texto = _normalizar('${e.cargo} ${e.empresa} ${e.descricao ?? ''}');
      if (keywords.any(texto.contains)) relevantes++;
    }

    final ratio = relevantes / experiencias.length;
    return _ratioToScore(ratio);
  }

  double _scoreFormacao(
    String resumo,
    String vagaTexto,
    List<Formacao> formacoes,
  ) {
    if (formacoes.isEmpty && resumo.isEmpty) return 0.0;

    final exigeSuperior = _contemAlgum(vagaTexto, [
      'graduacao',
      'superior',
      'bacharelado',
      'licenciatura',
      'pos',
      'mestrado',
      'doutorado',
      'mba',
    ]);

    final vagaTi = _ehVagaTi(vagaTexto);
    final cursoTi = formacoes.any((f) => _tiCursos
            .any((c) => _normalizar(f.curso).contains(_normalizar(c)))) ||
        _tiCursos.any((c) => resumo.contains(_normalizar(c)));

    final nivel = _nivelMaisAlto(formacoes, resumo);
    final idx = _nivelFormacaoOrdem.indexOf(nivel);

    if (exigeSuperior) {
      if (idx >= _nivelFormacaoOrdem.indexOf('graduacao')) {
        return cursoTi && vagaTi ? 5.0 : 4.0;
      }
      return idx > 0 ? 2.0 : 1.0;
    }

    if (cursoTi && vagaTi) return 4.0;
    return idx > 0 ? 2.0 : 0.0;
  }

  double _scoreIdiomas(
    String resumo,
    String vagaTexto,
    List<Idioma> idiomas,
  ) {
    final requeridos =
        _idiomasConhecidos.where((i) => vagaTexto.contains(i)).toList();
    final candIdiomas = {
      for (final i in idiomas) _normalizar(i.nome),
      for (final i in _idiomasConhecidos)
        if (resumo.contains(i)) i,
    };

    if (requeridos.isEmpty) {
      return candIdiomas.isNotEmpty ? 2.0 : 0.0;
    }

    var match = 0;
    for (final i in requeridos) {
      if (candIdiomas.contains(i)) match++;
    }

    final ratio = match / requeridos.length;
    return _ratioToScore(ratio);
  }

  double _calcularTotal(Map<String, double> scores) {
    final total =
        (scores['hard_skills']! / 5.0) * RankingConfig.pesoHardSkills +
            (scores['experiencia']! / 5.0) * RankingConfig.pesoExperiencia +
            (scores['formacao']! / 5.0) * RankingConfig.pesoFormacao +
            (scores['idiomas']! / 5.0) * RankingConfig.pesoIdiomas +
            (scores['soft_skills']! / 5.0) * RankingConfig.pesoSoftSkills;
    return double.parse((total * 100).toStringAsFixed(1));
  }

  List<String> _requisitosHardSkills(Vaga vaga) {
    final base = (vaga.habilidades ?? [])
        .map(_normalizarSkill)
        .where((s) => s.isNotEmpty)
        .toList();
    if (base.isNotEmpty) return base.toSet().toList();
    final raw = _splitKeywords(vaga.requisitos ?? '');
    return raw
        .map(_normalizarSkill)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _extrairKeywordsVaga(String vagaTexto) {
    final keywords = <String>{};
    for (final k in _tiKeywords) {
      if (vagaTexto.contains(_normalizar(k))) keywords.add(_normalizarSkill(k));
    }
    return keywords.toList();
  }

  bool _ehVagaTi(String vagaTexto) =>
      _tiKeywords.any((k) => vagaTexto.contains(_normalizar(k)));

  String _nivelMaisAlto(List<Formacao> formacoes, String resumo) {
    String? nivel;
    for (final f in formacoes) {
      final n = _normalizar(f.nivel);
      if (n.isNotEmpty) {
        if (nivel == null ||
            _nivelFormacaoOrdem.indexOf(n) >
                _nivelFormacaoOrdem.indexOf(nivel)) {
          nivel = n;
        }
      }
    }

    if (nivel == null) {
      for (final n in _nivelFormacaoOrdem.reversed) {
        if (resumo.contains(n)) {
          nivel = n;
          break;
        }
      }
    }

    return nivel ?? '';
  }

  List<String> _extrairRequisitosObrigatorios(Vaga vaga) {
    if (vaga.habilidades != null && vaga.habilidades!.isNotEmpty) {
      return vaga.habilidades!
          .map(_normalizarSkill)
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return _splitKeywords(vaga.requisitos ?? '')
        .map(_normalizarSkill)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _faltandoRequisitos(
    String resumo,
    List<Habilidade> habilidades,
    List<String> requisitos,
  ) {
    if (requisitos.isEmpty) return [];
    final candSkills = <String>{
      for (final h in habilidades) _normalizarSkill(h.nome),
    };
    final faltantes = <String>[];
    for (final r in requisitos) {
      if (!candSkills.contains(r) && !resumo.contains(r)) {
        faltantes.add(r);
      }
    }
    return faltantes;
  }

  List<String> _splitKeywords(String texto) => texto
      .split(RegExp(r'[,;\n\|/]'))
      .map((s) => s.trim())
      .where((s) => s.length >= 2)
      .toList();

  double _ratioToScore(double ratio) {
    if (ratio <= 0) return 0.0;
    if (ratio < 0.25) return 1.0;
    if (ratio < 0.5) return 2.0;
    if (ratio < 0.75) return 3.0;
    if (ratio < 1.0) return 4.0;
    return 5.0;
  }

  String _normalizar(String texto) {
    var t = texto.toLowerCase();
    t = t
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
    return t;
  }

  String _normalizarSkill(String skill) {
    final s = _normalizar(skill);
    return _skillAliases[s] ?? s;
  }

  bool _contemAlgum(String texto, List<String> termos) =>
      termos.any((t) => texto.contains(_normalizar(t)));
}

class RankingDetalhado {
  const RankingDetalhado({
    required this.scoreTotal,
    required this.scoresPorEixo,
    required this.gatingAprovado,
    required this.requisitosNaoAtendidos,
  });

  final double scoreTotal;
  final Map<String, double> scoresPorEixo;
  final bool gatingAprovado;
  final List<String> requisitosNaoAtendidos;

  Map<String, dynamic> toMap() => {
        'score': scoreTotal,
        'score_total': scoreTotal,
        'scores_por_eixo': scoresPorEixo,
        'gating_aprovado': gatingAprovado,
        'requisitos_nao_atendidos': requisitosNaoAtendidos,
      };
}

class _CandidaturaComScore {
  const _CandidaturaComScore(this.candidatura, this.score);
  final Candidatura candidatura;
  final double score;
}
