import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rh_os/data/parsers/extrator_dados.dart';
import 'package:rh_os/data/parsers/ocr/gemini_ocr_service.dart';
import 'package:rh_os/data/parsers/pdf_parser.dart';
import 'package:rh_os/data/parsers/txt_parser.dart';

class ExtrairDadosCurriculo {
  ExtrairDadosCurriculo({
    PdfParser? pdfParser,
    TxtParser? txtParser,
    ExtratorDados? extrator,
  })  : _pdf = pdfParser ?? PdfParser(),
        _txt = txtParser ?? TxtParser(),
        _extrator = extrator ?? ExtratorDados();

  final PdfParser _pdf;
  final TxtParser _txt;
  final ExtratorDados _extrator;

  // Extracao a partir de bytes (upload).
  Future<Map<String, dynamic>> executarComBytes(
      Uint8List bytes, String extensao,
      {void Function(String)? onProgresso}) async {
    if (extensao == 'pdf') {
      onProgresso?.call('Analisando com IA (Gemini 2.5 Flash)...');
      debugPrint('[ExtrairDados] PDF → Gemini 2.5 Flash');
      final gemini = GeminiOcrService();
      final resultado =
          await gemini.extrairDadosDosBytes(bytes, 'application/pdf');

      if (resultado != null && resultado.isNotEmpty) {
        debugPrint(
            '[ExtrairDados] Gemini retornou ${resultado.keys.length} campos');
        final normalizado = _normalizar(resultado);

        if (_precisaComplemento(normalizado)) {
          onProgresso?.call('Complementando dados...');
          final texto = await _pdf.extrairTextoDosBytes(bytes);
          final fallback = _normalizar(_extrator.extrair(texto));
          return _mesclarDados(normalizado, fallback);
        }

        return normalizado;
      }

      debugPrint('[ExtrairDados] Gemini falhou — fallback regex');
      // E8: mensagem clara quando a IA falha e o fallback regex é usado.
      onProgresso?.call('IA indisponível — extraindo via regex...');
      final texto = await _pdf.extrairTextoDosBytes(bytes);
      return _normalizar(_extrator.extrair(texto));
    }

    onProgresso?.call('Extraindo dados do arquivo...');
    final texto = utf8.decode(bytes, allowMalformed: true);
    return _normalizar(_extrator.extrair(texto));
  }

  // Extracao a partir de arquivo local.
  Future<Map<String, dynamic>> executar(String caminho) async {
    try {
      final extensao = caminho.split('.').last.toLowerCase();
      final String texto;

      if (extensao == 'pdf') {
        texto = await _pdf.extrairTexto(caminho);
      } else {
        texto = await _txt.extrairTexto(caminho);
      }

      if (texto.isEmpty) return _mapaVazio();
      return _normalizar(_extrator.extrair(texto));
    } catch (_) {
      return _mapaVazio();
    }
  }

  Map<String, dynamic> _normalizar(Map<String, dynamic> input) {
    final normalizado = Map<String, dynamic>.from(input);

    String? str(List<String> chaves) {
      for (final chave in chaves) {
        final valor = normalizado[chave];
        if (valor is String) {
          final v = valor.trim();
          if (v.isNotEmpty) return v;
        }
      }
      return null;
    }

    void put(String chave, String? valor) {
      if (valor != null && valor.isNotEmpty) {
        normalizado[chave] = valor;
      }
    }

    put('nome', str(['nome', 'nome_completo', 'nomeCompleto', 'full_name']));
    put('email', str(['email']));
    put('telefone', str(['telefone', 'celular']));
    put('cpf', str(['cpf']));
    put('dataNascimento', str(['dataNascimento', 'data_nascimento']));
    put('logradouro', str(['logradouro', 'rua', 'endereco']));
    put('numero', str(['numero']));
    put('bairro', str(['bairro']));
    put('cidade', str(['cidade']));
    put('estado', str(['estado', 'uf']));
    put('cep', str(['cep']));
    put('resumo', str(['resumo', 'resumo_profissional', 'objetivo']));

    _corrigirTelefoneCep(normalizado);

    normalizado['habilidades'] = _normalizarLista(normalizado['habilidades']);
    normalizado['experiencias'] =
        _normalizarExperiencias(normalizado['experiencias']);
    normalizado['formacoes'] = _normalizarFormacoes(normalizado['formacoes']);
    normalizado['idiomas'] = _normalizarIdiomas(normalizado['idiomas']);

    return normalizado;
  }

  List<String> _normalizarLista(dynamic valor) {
    if (valor is List) {
      return valor
          .map((v) {
            if (v is String) return v.trim();
            if (v is Map && v['nome'] is String) {
              return (v['nome'] as String).trim();
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (valor is String) {
      return valor
          .split(RegExp(r'[,;\n\|/]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _normalizarExperiencias(dynamic valor) {
    if (valor is! List) return <Map<String, dynamic>>[];
    final resultado = <Map<String, dynamic>>[];

    for (final item in valor) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);

      final empresa = _strMap(m, ['empresa', 'company', 'empresa_nome']);
      final cargo = _strMap(m, ['cargo', 'funcao', 'title']);
      final descricao = _strMap(m, ['descricao', 'description']);
      final dataInicio = _strMap(m, ['dataInicio', 'data_inicio', 'inicio']);
      final dataFim = _strMap(m, ['dataFim', 'data_fim', 'fim']);
      final atual = _boolMap(m, ['atual', 'current']);

      final novo = <String, dynamic>{
        'empresa': empresa,
        'cargo': cargo,
        'descricao': descricao,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'atual': atual,
      };

      if (!_isVazio(novo['empresa']) || !_isVazio(novo['cargo'])) {
        resultado.add(novo);
      }
    }

    return resultado;
  }

  List<Map<String, dynamic>> _normalizarFormacoes(dynamic valor) {
    if (valor is! List) return <Map<String, dynamic>>[];
    final resultado = <Map<String, dynamic>>[];

    for (final item in valor) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);

      final instituicao =
          _strMap(m, ['instituicao', 'instituição', 'instituicao_nome']);
      final curso = _strMap(m, ['curso']);
      final nivel = _strMap(m, ['nivel', 'grau', 'nivelFormacao']);
      final dataInicio = _strMap(m, ['dataInicio', 'data_inicio', 'inicio']);
      final dataFim = _strMap(m, ['dataFim', 'data_fim', 'fim']);
      final anoConclusao = _strMap(m, ['anoConclusao', 'ano_conclusao']);
      final emAndamento =
          _boolMap(m, ['emAndamento', 'em_andamento', 'andamento']);

      final novo = <String, dynamic>{
        'instituicao': instituicao,
        'curso': curso,
        'nivel': nivel,
        'dataInicio': dataInicio,
        'dataFim': dataFim ?? anoConclusao,
        'emAndamento': emAndamento,
      };

      if (!_isVazio(novo['instituicao']) || !_isVazio(novo['curso'])) {
        resultado.add(novo);
      }
    }

    return resultado;
  }

  List<Map<String, String>> _normalizarIdiomas(dynamic valor) {
    if (valor is! List) return <Map<String, String>>[];
    final resultado = <Map<String, String>>[];

    for (final item in valor) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final nome = _strMap(m, ['nome', 'idioma', 'language']);
        final nivel = _strMap(m, ['nivel', 'level']) ?? 'basico';
        if (nome != null && nome.isNotEmpty) {
          resultado.add({'nome': nome, 'nivel': nivel});
        }
        continue;
      }

      if (item is String) {
        final raw = item.trim();
        if (raw.isEmpty) continue;
        final parts = raw.split(RegExp(r'[-–—]'));
        final nome = parts.first.trim();
        final nivel = parts.length > 1 ? parts[1].trim() : 'basico';
        if (nome.isNotEmpty) {
          resultado.add({'nome': nome, 'nivel': nivel});
        }
      }
    }

    return resultado;
  }

  String? _strMap(Map<String, dynamic> m, List<String> chaves) {
    for (final chave in chaves) {
      final valor = m[chave];
      if (valor is String) {
        final v = valor.trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  bool _boolMap(Map<String, dynamic> m, List<String> chaves) {
    for (final chave in chaves) {
      final valor = m[chave];
      if (valor is bool) return valor;
      if (valor is int) return valor == 1;
      if (valor is String) {
        final v = valor.toLowerCase().trim();
        if (v == 'true' || v == 'sim' || v == '1') return true;
      }
    }
    return false;
  }

  void _corrigirTelefoneCep(Map<String, dynamic> dados) {
    final telefone = dados['telefone'] as String?;
    final cep = dados['cep'] as String?;

    final telDigits = _digits(telefone);
    final cepDigits = _digits(cep);

    if (!_isVazio(telefone) && _looksLikeCep(telDigits) && _isVazio(cep)) {
      dados['cep'] = telefone;
      dados['telefone'] = null;
      return;
    }

    if (!_isVazio(cep) && _looksLikePhone(cepDigits) && _isVazio(telefone)) {
      dados['telefone'] = cep;
      dados['cep'] = null;
      return;
    }

    if (!_isVazio(cep) && !_looksLikeCep(cepDigits)) {
      if (_looksLikePhone(cepDigits) && _isVazio(telefone)) {
        dados['telefone'] = cep;
      }
      dados['cep'] = null;
    }

    if (!_isVazio(telefone) && !_looksLikePhone(telDigits)) {
      if (_looksLikeCep(telDigits) && _isVazio(cep)) {
        dados['cep'] = telefone;
      }
      dados['telefone'] = null;
    }
  }

  String? _digits(String? value) {
    if (value == null) return null;
    final d = value.replaceAll(RegExp(r'\D'), '');
    return d.isEmpty ? null : d;
  }

  bool _looksLikeCep(String? digits) => digits != null && digits.length == 8;

  bool _looksLikePhone(String? digits) {
    if (digits == null) return false;
    return digits.length == 9 || digits.length == 10 || digits.length == 11;
  }

  bool _precisaComplemento(Map<String, dynamic> dados) {
    return _isVazio(dados['nome']) ||
        _isVazio(dados['email']) ||
        _isVazio(dados['cpf']) ||
        _isVazio(dados['telefone']);
  }

  bool _isVazio(dynamic valor) {
    if (valor == null) return true;
    if (valor is String) return valor.trim().isEmpty;
    if (valor is List) return valor.isEmpty;
    return false;
  }

  Map<String, dynamic> _mesclarDados(
    Map<String, dynamic> principal,
    Map<String, dynamic> fallback,
  ) {
    final combinado = Map<String, dynamic>.from(principal);
    fallback.forEach((chave, valor) {
      if (_isVazio(combinado[chave]) && !_isVazio(valor)) {
        combinado[chave] = valor;
      }
    });
    return combinado;
  }

  Map<String, dynamic> _mapaVazio() => {
        'nome': null,
        'email': null,
        'telefone': null,
        'cpf': null,
        'cep': null,
        'dataNascimento': null,
        'sexo': null,
        'logradouro': null,
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
