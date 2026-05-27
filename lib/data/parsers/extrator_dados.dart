// Heuristica de extracao por regex para curriculos em texto.
class ExtratorDados {
  // Regex de campos basicos.
  static final _reEmail =
      RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}');
  static final _reTelefone =
      RegExp(r'(\+55\s?)?(\(?\d{2}\)?\s?)?(\d{4,5}[\s\-]?\d{4})');
  static final _reCpf = RegExp(r'\d{3}\.?\d{3}\.?\d{3}[\-]?\d{2}');
  static final _reCep = RegExp(r'\d{5}[\-]?\d{3}');
  static final _reData = RegExp(r'\d{2}/\d{2}/\d{4}|\d{4}-\d{2}-\d{2}');

  // Regex de titulos de secao.
  static final _reResumo =
      RegExp(r'(resumo|objetivo|sobre mim)', caseSensitive: false);
  static final _reExperiencia =
      RegExp(r'(experi[êe]ncia|hist[oó]rico|atua[çc])', caseSensitive: false);
  static final _reFormacao =
      RegExp(r'(forma[çc][aã]o|educa[çc][aã]o)', caseSensitive: false);
  static final _reHabilidades =
      RegExp(r'(habilidades|skills|compet[êe]ncias)', caseSensitive: false);
  static final _reIdiomas =
      RegExp(r'(idiomas|l[íi]nguas)', caseSensitive: false);

  // Regex auxiliares.
  static final _reEstados = RegExp(
    r'\b(AC|AL|AP|AM|BA|CE|DF|ES|GO|MA|MT|MS|MG|PA|PB|PR|PE|PI|RJ|RN|RS|RO|RR|SC|SP|SE|TO)\b',
  );
  static final _rePeriodo = RegExp(
    r'(\d{2}/\d{4}|\d{4})\s*[-–—]\s*(\d{2}/\d{4}|\d{4}|atual|presente|current)',
    caseSensitive: false,
  );
  static final _reNivelIdioma = RegExp(
    r'(b[aá]sico|elementar|intermedi[aá]rio|avan[çc]ado|fluente|nativo)',
    caseSensitive: false,
  );
  static final _reNivelFormacao = RegExp(
    r'(ensino m[eé]dio|gradua[çc][aã]o|bacharelado|licenciatura|tecn[oó]logo|'
    r'p[oó]s[\s\-]gradua[çc][aã]o|especializa[çc][aã]o|mestrado|doutorado|mba)',
    caseSensitive: false,
  );

  // Extrai dados estruturados a partir de texto bruto.
  Map<String, dynamic> extrair(String textoBreto) {
    try {
      final linhas =
          textoBreto.split(RegExp(r'\r?\n')).map((l) => l.trim()).toList();

      final email = _reEmail.firstMatch(textoBreto)?.group(0);
      final telefone = _reTelefone.firstMatch(textoBreto)?.group(0);
      final cpf = _reCpf.firstMatch(textoBreto)?.group(0);
      final cep = _reCep.firstMatch(textoBreto)?.group(0);
      final estado = _reEstados.firstMatch(textoBreto)?.group(0);

      // Data de nascimento: evita datas de periodo profissional.
      String? dataNascimento;
      for (final m in _reData.allMatches(textoBreto)) {
        final ctx = textoBreto.substring(
          (m.start - 30).clamp(0, textoBreto.length),
          m.start,
        );
        if (!ctx.toLowerCase().contains(RegExp(r'inicio|início|admiss'))) {
          dataNascimento = m.group(0);
          break;
        }
      }

      // Nome: primeira linha valida fora de secoes.
      String? nome;
      for (final linha in linhas) {
        if (linha.length < 3) continue;
        if (_reEmail.hasMatch(linha)) continue;
        if (_reTelefone.hasMatch(linha)) continue;
        if (_reResumo.hasMatch(linha) ||
            _reExperiencia.hasMatch(linha) ||
            _reFormacao.hasMatch(linha) ||
            _reHabilidades.hasMatch(linha) ||
            _reIdiomas.hasMatch(linha)) {
          continue;
        }
        if (RegExp(r'^\d').hasMatch(linha)) continue;
        // Aceita linhas que parecem nomes (palavras com maiúsculas)
        if (RegExp(r'^[A-ZÀ-Ú][a-zà-ú]').hasMatch(linha) &&
            linha.split(' ').length <= 6) {
          nome = linha;
          break;
        }
      }

      // Cidade: linha com UF abreviada.
      String? cidade;
      for (final linha in linhas) {
        if (_reEstados.hasMatch(linha) && linha.length < 60) {
          final partes = linha.split(RegExp(r'[,\-/]'));
          if (partes.isNotEmpty) {
            cidade = partes.first.trim().replaceAll(_reEstados, '').trim();
          }
          break;
        }
      }

      final secoes = _dividirEmSecoes(linhas);

      final resumo = secoes['resumo'];
      final expTexto = secoes['experiencia'] ?? '';
      final formTexto = secoes['formacao'] ?? '';
      final habTexto = secoes['habilidades'] ?? '';
      final idiomasTexto = secoes['idiomas'] ?? '';

      final experiencias = _extrairExperiencias(expTexto);

      final formacoes = _extrairFormacoes(formTexto);

      final habilidades = _extrairHabilidades(habTexto);

      final idiomas = _extrairIdiomas(idiomasTexto);

      return {
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'cpf': cpf,
        'cep': cep,
        'dataNascimento': dataNascimento,
        'sexo': null,
        'rua': null,
        'numero': null,
        'bairro': null,
        'cidade': cidade,
        'estado': estado,
        'resumo': resumo,
        'experiencias': experiencias,
        'formacoes': formacoes,
        'habilidades': habilidades,
        'idiomas': idiomas,
      };
    } catch (_) {
      return _mapaVazio();
    }
  }

  // Divide o texto em secoes por cabecalhos reconhecidos.
  Map<String, String> _dividirEmSecoes(List<String> linhas) {
    final secoes = <String, String>{};
    String? secaoAtual;
    final buffer = StringBuffer();

    for (final linha in linhas) {
      String? novaSecao;
      if (_reResumo.hasMatch(linha) && linha.length < 40) {
        novaSecao = 'resumo';
      } else if (_reExperiencia.hasMatch(linha) && linha.length < 40) {
        novaSecao = 'experiencia';
      } else if (_reFormacao.hasMatch(linha) && linha.length < 40) {
        novaSecao = 'formacao';
      } else if (_reHabilidades.hasMatch(linha) && linha.length < 40) {
        novaSecao = 'habilidades';
      } else if (_reIdiomas.hasMatch(linha) && linha.length < 40) {
        novaSecao = 'idiomas';
      }

      if (novaSecao != null) {
        if (secaoAtual != null) secoes[secaoAtual] = buffer.toString().trim();
        secaoAtual = novaSecao;
        buffer.clear();
      } else if (secaoAtual != null) {
        buffer.writeln(linha);
      }
    }
    if (secaoAtual != null) secoes[secaoAtual] = buffer.toString().trim();
    return secoes;
  }

  // Extrai lista de experiencias.
  List<Map<String, dynamic>> _extrairExperiencias(String texto) {
    if (texto.isEmpty) return [];
    final resultado = <Map<String, dynamic>>[];
    final blocos = _dividirEmBlocos(texto);

    for (final bloco in blocos) {
      if (bloco.trim().isEmpty) continue;
      final linhas = bloco
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (linhas.isEmpty) continue;

      final periodoMatch = _rePeriodo.firstMatch(bloco);
      final atual =
          bloco.toLowerCase().contains(RegExp(r'atual|presente|current'));

      resultado.add({
        'empresa': linhas.length > 1 ? linhas[0].trim() : null,
        'cargo': linhas.length > 1 ? linhas[1].trim() : linhas[0].trim(),
        'descricao':
            linhas.length > 2 ? linhas.sublist(2).join(' ').trim() : null,
        'dataInicio': periodoMatch?.group(1),
        'dataFim': atual ? null : periodoMatch?.group(2),
        'atual': atual,
      });
    }
    return resultado;
  }

  // Extrai lista de formacoes.
  List<Map<String, dynamic>> _extrairFormacoes(String texto) {
    if (texto.isEmpty) return [];
    final resultado = <Map<String, dynamic>>[];
    final blocos = _dividirEmBlocos(texto);

    for (final bloco in blocos) {
      if (bloco.trim().isEmpty) continue;
      final linhas = bloco
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (linhas.isEmpty) continue;

      final nivelMatch = _reNivelFormacao.firstMatch(bloco);
      final periodoMatch = _rePeriodo.firstMatch(bloco);
      final emAndamento =
          bloco.toLowerCase().contains(RegExp(r'andamento|cursando|em curso'));

      resultado.add({
        'instituicao': linhas[0].trim(),
        'curso': linhas.length > 1 ? linhas[1].trim() : null,
        'nivel': nivelMatch?.group(0)?.toLowerCase() ?? 'graduacao',
        'dataInicio': periodoMatch?.group(1),
        'dataFim': emAndamento ? null : periodoMatch?.group(2),
        'emAndamento': emAndamento,
      });
    }
    return resultado;
  }

  // Extrai lista de habilidades como strings.
  List<String> _extrairHabilidades(String texto) {
    if (texto.isEmpty) return [];
    return texto
        .split(RegExp(r'[,;|\n•·▪\-]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length < 60)
        .toList();
  }

  // Extrai lista de idiomas com nivel.
  List<Map<String, dynamic>> _extrairIdiomas(String texto) {
    if (texto.isEmpty) return [];
    final resultado = <Map<String, dynamic>>[];

    for (final linha in texto.split(RegExp(r'\r?\n'))) {
      final l = linha.trim();
      if (l.isEmpty || l.length > 80) continue;
      final nivelMatch = _reNivelIdioma.firstMatch(l);
      final nomeIdioma = l
          .replaceAll(_reNivelIdioma, '')
          .replaceAll(RegExp(r'[-–:,]'), '')
          .trim();
      if (nomeIdioma.isNotEmpty) {
        resultado.add({
          'nome': nomeIdioma,
          'nivel': nivelMatch?.group(0)?.toLowerCase() ?? 'basico',
        });
      }
    }
    return resultado;
  }

  // Divide texto em blocos separados por linha vazia.
  List<String> _dividirEmBlocos(String texto) => texto
      .split(RegExp(r'\n\s*\n'))
      .where((b) => b.trim().isNotEmpty)
      .toList();

  Map<String, dynamic> _mapaVazio() => {
        'nome': null,
        'email': null,
        'telefone': null,
        'cpf': null,
        'cep': null,
        'dataNascimento': null,
        'sexo': null,
        'rua': null,
        'numero': null,
        'bairro': null,
        'cidade': null,
        'estado': null,
        'resumo': null,
        'experiencias': <Map<String, dynamic>>[],
        'formacoes': <Map<String, dynamic>>[],
        'habilidades': <String>[],
        'idiomas': <Map<String, dynamic>>[],
      };
}
