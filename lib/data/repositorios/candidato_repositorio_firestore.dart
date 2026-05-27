// Repositorio de candidatos no Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:rh_os/core/utils/validadores.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/entidades/experiencia.dart';
import 'package:rh_os/domain/entidades/formacao.dart';
import 'package:rh_os/domain/entidades/habilidade.dart';
import 'package:rh_os/domain/entidades/idioma.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';

class CandidatoRepositorioFirestore implements ICandidatoRepositorio {
  final _col = FirebaseFirestore.instance.collection('candidatos');

  // Converte e normaliza entidade para persistencia.
  Map<String, dynamic> _toFirestore(Candidato c) {
    final map = c.toMap();
    map.remove('id');
    map.remove('idStr');
    map['telefone'] =
        Validadores.normalizarTelefone(map['telefone'] as String?);
    map['cep'] = Validadores.normalizarCep(map['cep'] as String?);
    return map;
  }

  // Mapeia experiencias para o schema persistido.
  List<Map<String, dynamic>> _mapExperiencias(
      List<Map<String, dynamic>> itens) {
    return itens
        .map((e) {
          final empresa = _limparStr(e['empresa']);
          final cargo = _limparStr(e['cargo']);
          if (empresa.isEmpty && cargo.isEmpty) return null;
          return <String, dynamic>{
            'empresa': empresa,
            'cargo': cargo,
            'descricao': _limparStr(e['descricao']),
            'data_inicio': _limparStr(e['dataInicio'] ?? e['data_inicio']),
            'data_fim': _limparStr(e['dataFim'] ?? e['data_fim']),
            'atual': e['atual'] == true,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // Mapeia formacoes para o schema persistido.
  List<Map<String, dynamic>> _mapFormacoes(List<Map<String, dynamic>> itens) {
    return itens
        .map((f) {
          final instituicao = _limparStr(f['instituicao']);
          final curso = _limparStr(f['curso']);
          if (instituicao.isEmpty && curso.isEmpty) return null;
          return <String, dynamic>{
            'instituicao': instituicao,
            'curso': curso,
            'nivel': _limparStr(f['nivel']),
            'data_inicio': _limparStr(f['dataInicio'] ?? f['data_inicio']),
            'data_fim': _limparStr(f['dataFim'] ?? f['data_fim']),
            'em_andamento': f['emAndamento'] == true,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // Deduplica e limpa habilidades.
  List<String> _mapHabilidades(List<String> itens) {
    return itens
        .map((h) => h.trim())
        .where((h) => h.isNotEmpty)
        .toSet()
        .toList();
  }

  // Mapeia idiomas para o schema persistido.
  List<Map<String, dynamic>> _mapIdiomas(List<Map<String, dynamic>> itens) {
    return itens
        .map((i) {
          final nome = _limparStr(i['nome']);
          if (nome.isEmpty) return null;
          return <String, dynamic>{
            'nome': nome,
            'nivel': _limparStr(i['nivel']).isEmpty ? 'basico' : i['nivel'],
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // Normaliza valor para string.
  String _limparStr(dynamic valor) {
    if (valor == null) return '';
    return valor.toString().trim();
  }

  // Converte documento do Firestore em entidade.
  Candidato _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Candidato.fromMap({...data, 'idStr': doc.id});
  }

  // Reconstrui experiencias a partir do documento.
  List<Experiencia> _fromExperiencias(List<dynamic> raw) {
    final resultado = <Experiencia>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final empresa = _limparStr(m['empresa']);
      final cargo = _limparStr(m['cargo']);
      if (empresa.isEmpty && cargo.isEmpty) continue;

      final dataInicio = _limparStr(m['data_inicio'] ?? m['dataInicio']);
      final dataFim = _limparStr(m['data_fim'] ?? m['dataFim']);
      final atual = m['atual'] == true;

      resultado.add(Experiencia(
        candidatoId: 0,
        empresa: empresa.isEmpty ? '-' : empresa,
        cargo: cargo.isEmpty ? '-' : cargo,
        descricao: _limparStr(m['descricao']).isEmpty
            ? null
            : _limparStr(m['descricao']),
        dataInicio: dataInicio.isEmpty ? '-' : dataInicio,
        dataFim: dataFim.isEmpty ? null : dataFim,
        atual: atual,
      ));
    }
    return resultado;
  }

  // Reconstrui formacoes a partir do documento.
  List<Formacao> _fromFormacoes(List<dynamic> raw) {
    final resultado = <Formacao>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final instituicao = _limparStr(m['instituicao']);
      final curso = _limparStr(m['curso']);
      if (instituicao.isEmpty && curso.isEmpty) continue;

      final nivel = _limparStr(m['nivel']);
      final dataInicio = _limparStr(m['data_inicio'] ?? m['dataInicio']);
      final dataFim = _limparStr(m['data_fim'] ?? m['dataFim']);
      final emAndamento = m['em_andamento'] == true || m['emAndamento'] == true;

      resultado.add(Formacao(
        candidatoId: 0,
        instituicao: instituicao.isEmpty ? '-' : instituicao,
        curso: curso.isEmpty ? '-' : curso,
        nivel: nivel.isEmpty ? '-' : nivel,
        dataInicio: dataInicio.isEmpty ? '-' : dataInicio,
        dataFim: dataFim.isEmpty ? null : dataFim,
        emAndamento: emAndamento,
      ));
    }
    return resultado;
  }

  // Reconstrui habilidades a partir do documento.
  List<Habilidade> _fromHabilidades(List<dynamic> raw) {
    final resultado = <Habilidade>[];
    for (final item in raw) {
      if (item is String) {
        final nome = _limparStr(item);
        if (nome.isEmpty) continue;
        resultado.add(Habilidade(candidatoId: 0, nome: nome, nivel: 'basico'));
      } else if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final nome = _limparStr(m['nome']);
        if (nome.isEmpty) continue;
        final nivel =
            _limparStr(m['nivel']).isEmpty ? 'basico' : _limparStr(m['nivel']);
        resultado.add(Habilidade(candidatoId: 0, nome: nome, nivel: nivel));
      }
    }
    return resultado;
  }

  // Reconstrui idiomas a partir do documento.
  List<Idioma> _fromIdiomas(List<dynamic> raw) {
    final resultado = <Idioma>[];
    for (final item in raw) {
      if (item is String) {
        final nome = _limparStr(item);
        if (nome.isEmpty) continue;
        resultado.add(Idioma(candidatoId: 0, nome: nome, nivel: 'basico'));
      } else if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final nome = _limparStr(m['nome']);
        if (nome.isEmpty) continue;
        final nivel =
            _limparStr(m['nivel']).isEmpty ? 'basico' : _limparStr(m['nivel']);
        resultado.add(Idioma(candidatoId: 0, nome: nome, nivel: nivel));
      }
    }
    return resultado;
  }

  @override
  // D7: try/catch em toda operação Firestore.
  Future<int> salvar(Candidato candidato) async {
    try {
      if (candidato.idStr != null) {
        await _col.doc(candidato.idStr).set(_toFirestore(candidato));
      } else {
        await _col.add(_toFirestore(candidato));
      }
    } catch (e, st) {
      debugPrint('[CandidatoRepo] salvar: $e');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'CandidatoRepo.salvar');
    }
    return 0;
  }

  // D7: try/catch — salvarCompleto não crasha o app em caso de erro.
  // E4: parâmetros de qualidade da extração persistidos no documento.
  @override
  Future<String> salvarCompleto(
    Candidato candidato, {
    List<Map<String, dynamic>> experiencias = const [],
    List<Map<String, dynamic>> formacoes = const [],
    List<String> habilidades = const [],
    List<Map<String, dynamic>> idiomas = const [],
    int camposPreenchidos = 0,
    int totalCampos = 12,
    String origemExtracao = 'desconhecido',
  }) async {
    final doc =
        candidato.idStr != null ? _col.doc(candidato.idStr) : _col.doc();
    try {
      final map = _toFirestore(candidato);
      map['experiencias'] = _mapExperiencias(experiencias);
      map['formacoes'] = _mapFormacoes(formacoes);
      map['habilidades'] = _mapHabilidades(habilidades);
      map['idiomas'] = _mapIdiomas(idiomas);
      // E4: metadados de qualidade da extração.
      map['extracao_campos_preenchidos'] = camposPreenchidos;
      map['extracao_total_campos'] = totalCampos;
      map['extracao_origem'] = origemExtracao;
      map['extracao_data'] = DateTime.now().toIso8601String();
      await doc.set(map, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('[CandidatoRepo] salvarCompleto: $e');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'CandidatoRepo.salvarCompleto');
    }
    return doc.id;
  }

  @override
  // D7: try/catch — atualizar não crasha o app.
  Future<int> atualizar(Candidato candidato) async {
    try {
      if (candidato.idStr != null) {
        await _col.doc(candidato.idStr).set(_toFirestore(candidato));
      }
    } catch (e) {
      debugPrint('[CandidatoRepo] atualizar: $e');
    }
    return 0;
  }

  @override
  // D2: stub int ignorado — use deletarPorIdStr(String).
  Future<int> deletar(int id) async {
    debugPrint('[CandidatoRepo] deletar(int) ignorado — usar deletarPorIdStr');
    return 0;
  }

  @override
  // D2: stub int ignorado — use buscarPorIdStr(String).
  Future<Candidato?> buscarPorId(int id) async {
    debugPrint(
        '[CandidatoRepo] buscarPorId(int) ignorado — usar buscarPorIdStr');
    return null;
  }

  @override
  // D2: stub int ignorado — use buscarPorUsuarioUid(String).
  Future<Candidato?> buscarPorUsuarioId(int usuarioId) async {
    debugPrint(
        '[CandidatoRepo] buscarPorUsuarioId(int) ignorado — usar buscarPorUsuarioUid');
    return null;
  }

  @override
  // D7: try/catch — listarTodos retorna [] em caso de erro Firestore.
  Future<List<Candidato>> listarTodos() async {
    try {
      final snap = await _col.get();
      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('[CandidatoRepo] listarTodos: $e');
      return [];
    }
  }

  @override
  // D7: try/catch — buscarPorNome retorna [] em caso de erro.
  Future<List<Candidato>> buscarPorNome(String termo) async {
    try {
      final snap = await _col
          .where('nome', isGreaterThanOrEqualTo: termo)
          .where('nome', isLessThanOrEqualTo: '$termo')
          .get();
      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('[CandidatoRepo] buscarPorNome: $e');
      return [];
    }
  }

  @override
  Future<int> salvarExperiencia(Experiencia e) async => 0;

  @override
  Future<int> deletarExperiencia(int id) async => 0;

  @override
  Future<List<Experiencia>> listarExperiencias(int candidatoId) async => [];

  @override
  Future<int> salvarFormacao(Formacao f) async => 0;

  @override
  Future<int> deletarFormacao(int id) async => 0;

  @override
  Future<List<Formacao>> listarFormacoes(int candidatoId) async => [];

  @override
  Future<int> salvarHabilidade(Habilidade h) async => 0;

  @override
  Future<int> deletarHabilidade(int id) async => 0;

  @override
  Future<List<Habilidade>> listarHabilidades(int candidatoId) async => [];

  @override
  Future<int> salvarIdioma(Idioma i) async => 0;

  @override
  Future<int> deletarIdioma(int id) async => 0;

  @override
  Future<List<Idioma>> listarIdiomas(int candidatoId) async => [];

  @override
  // D7: try/catch — contarTotal retorna 0 em caso de erro.
  Future<int> contarTotal() async {
    try {
      final snap = await _col.get();
      return snap.docs.length;
    } catch (e) {
      debugPrint('[CandidatoRepo] contarTotal: $e');
      return 0;
    }
  }

  @override
  // D2: stub int ignorado — use atualizarCampoStr(String, ...).
  Future<int> atualizarCampo(int id, String campo, String valor) async {
    debugPrint(
        '[CandidatoRepo] atualizarCampo(int) ignorado — usar atualizarCampoStr');
    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> listarTopHabilidades(int limite) async =>
      [];

  // D7: try/catch — buscarPorUsuarioUid retorna null em caso de erro.
  @override
  Future<Candidato?> buscarPorUsuarioUid(String uid) async {
    try {
      final snap =
          await _col.where('usuario_uid', isEqualTo: uid).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return _fromDoc(snap.docs.first);
    } catch (e) {
      debugPrint('[CandidatoRepo] buscarPorUsuarioUid: $e');
      return null;
    }
  }

  // D7: try/catch — buscarPorEmail retorna null em caso de erro.
  @override
  Future<Candidato?> buscarPorEmail(String email) async {
    try {
      final snap = await _col.where('email', isEqualTo: email).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return _fromDoc(snap.docs.first);
    } catch (e) {
      debugPrint('[CandidatoRepo] buscarPorEmail: $e');
      return null;
    }
  }

  // D7: try/catch — buscarPorCpf retorna null em caso de erro.
  @override
  Future<Candidato?> buscarPorCpf(String cpf) async {
    try {
      final snap = await _col.where('cpf', isEqualTo: cpf).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return _fromDoc(snap.docs.first);
    } catch (e) {
      debugPrint('[CandidatoRepo] buscarPorCpf: $e');
      return null;
    }
  }

  // D7: try/catch — deletarPorIdStr não crasha o app.
  @override
  Future<void> deletarPorIdStr(String idStr) async {
    try {
      await _col.doc(idStr).delete();
    } catch (e, st) {
      debugPrint('[CandidatoRepo] deletarPorIdStr: $e');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'CandidatoRepo.deletarPorIdStr');
    }
  }

  // D7: try/catch — atualizarCampoStr não crasha o app.
  @override
  Future<void> atualizarCampoStr(
      String idStr, String campo, String valor) async {
    try {
      await _col.doc(idStr).update({campo: valor});
    } catch (e, st) {
      debugPrint('[CandidatoRepo] atualizarCampoStr: $e');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'CandidatoRepo.atualizarCampoStr');
    }
  }

  // D7: try/catch — buscarPorIdStr retorna null em caso de erro.
  @override
  Future<Candidato?> buscarPorIdStr(String idStr) async {
    try {
      final doc = await _col.doc(idStr).get();
      if (!doc.exists) return null;
      return _fromDoc(doc);
    } catch (e) {
      debugPrint('[CandidatoRepo] buscarPorIdStr: $e');
      return null;
    }
  }

  // D7: try/catch — listarExperienciasStr retorna [] em caso de erro.
  @override
  Future<List<Experiencia>> listarExperienciasStr(String idStr) async {
    try {
      final doc = await _col.doc(idStr).get();
      final data = doc.data();
      final raw = data?['experiencias'];
      if (raw is! List) return [];
      return _fromExperiencias(raw);
    } catch (e) {
      debugPrint('[CandidatoRepo] listarExperienciasStr: $e');
      return [];
    }
  }

  // D7: try/catch — listarFormacoesStr retorna [] em caso de erro.
  @override
  Future<List<Formacao>> listarFormacoesStr(String idStr) async {
    try {
      final doc = await _col.doc(idStr).get();
      final data = doc.data();
      final raw = data?['formacoes'];
      if (raw is! List) return [];
      return _fromFormacoes(raw);
    } catch (e) {
      debugPrint('[CandidatoRepo] listarFormacoesStr: $e');
      return [];
    }
  }

  // D7: try/catch — listarHabilidadesStr retorna [] em caso de erro.
  @override
  Future<List<Habilidade>> listarHabilidadesStr(String idStr) async {
    try {
      final doc = await _col.doc(idStr).get();
      final data = doc.data();
      final raw = data?['habilidades'];
      if (raw is! List) return [];
      return _fromHabilidades(raw);
    } catch (e) {
      debugPrint('[CandidatoRepo] listarHabilidadesStr: $e');
      return [];
    }
  }

  // D7: try/catch — listarIdiomasStr retorna [] em caso de erro.
  @override
  Future<List<Idioma>> listarIdiomasStr(String idStr) async {
    try {
      final doc = await _col.doc(idStr).get();
      final data = doc.data();
      final raw = data?['idiomas'];
      if (raw is! List) return [];
      return _fromIdiomas(raw);
    } catch (e) {
      debugPrint('[CandidatoRepo] listarIdiomasStr: $e');
      return [];
    }
  }
}
