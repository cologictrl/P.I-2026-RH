import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:rh_os/domain/entidades/candidatura.dart';
import 'package:rh_os/domain/repositorios/i_candidatura_repositorio.dart';

class CandidaturaRepositorioFirestore implements ICandidaturaRepositorio {
  // Colecao principal de candidaturas.
  final _col = FirebaseFirestore.instance.collection('candidaturas');

  // Converte entidade para mapa persistido.
  Map<String, dynamic> _toFirestore(Candidatura c) {
    final map = c.toMap();
    map.remove('id');
    map.remove('idStr');
    return map;
  }

  // Converte documento para entidade com idStr.
  Candidatura _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'data_candidatura': now,
      'atualizado_em': now,
      ...doc.data() ?? {},
      'idStr': doc.id,
    };
    return Candidatura.fromMap(data);
  }

  @override
  // D7: try/catch — salvar não crasha o app.
  Future<int> salvar(Candidatura candidatura) async {
    try {
      await _col.add(_toFirestore(candidatura));
    } catch (e) {
      debugPrint('[CandidaturaRepo] salvar: $e');
    }
    return 0;
  }

  @override
  // D7: try/catch — atualizar não crasha o app.
  Future<int> atualizar(Candidatura candidatura) async {
    try {
      if (candidatura.idStr != null) {
        await _col.doc(candidatura.idStr).set(_toFirestore(candidatura));
      }
    } catch (e) {
      debugPrint('[CandidaturaRepo] atualizar: $e');
    }
    return 0;
  }

  @override
  // D2: stub int ignorado — usar atualizarStatusStr(String, String).
  Future<int> atualizarStatus(int id, String status) async {
    debugPrint(
        '[CandidaturaRepo] atualizarStatus(int) ignorado — usar atualizarStatusStr');
    return 0;
  }

  @override
  // D2: stub int ignorado — usar atualizarScoreStr(String, double).
  Future<int> atualizarNota(int id, double nota) async {
    debugPrint(
        '[CandidaturaRepo] atualizarNota(int) ignorado — usar atualizarScoreStr');
    return 0;
  }

  @override
  // D2: stub int ignorado — candidaturas excluídas pelo idStr do documento.
  Future<int> deletar(int id) async {
    debugPrint('[CandidaturaRepo] deletar(int) ignorado — usar idStr');
    return 0;
  }

  @override
  // D2: stub int ignorado — usar listarPorVagaStr(String).
  Future<Candidatura?> buscarPorId(int id) async {
    debugPrint('[CandidaturaRepo] buscarPorId(int) ignorado — usar idStr');
    return null;
  }

  @override
  // D2: stub int ignorado — usar listarPorVagaStr(String).
  Future<List<Candidatura>> listarPorVaga(int vagaId) async {
    debugPrint(
        '[CandidaturaRepo] listarPorVaga(int) ignorado — usar listarPorVagaStr');
    return [];
  }

  @override
  // D2: stub int ignorado — usar listarPorCandidatoStr(String).
  Future<List<Candidatura>> listarPorCandidato(int candidatoId) async {
    debugPrint(
        '[CandidaturaRepo] listarPorCandidato(int) ignorado — usar listarPorCandidatoStr');
    return [];
  }

  @override
  Future<bool> existeCandidatura(int candidatoId, int vagaId) async => false;

  @override
  Future<Map<String, int>> contarPorStatus(int vagaId) async => {};

  @override
  Future<Map<String, int>> contarTodosPorStatus() async => {};

  @override
  Future<int> contarPorVaga(int vagaId) async => 0;

  @override
  // D2: stub int ignorado — usar atualizarScoreStr(String, double).
  Future<void> atualizarScore(int id, double score) async {
    debugPrint(
        '[CandidaturaRepo] atualizarScore(int) ignorado — usar atualizarScoreStr');
  }

  // D7: try/catch — listarPorVagaStr retorna [] em caso de erro Firestore.
  @override
  Future<List<Candidatura>> listarPorVagaStr(String vagaIdStr) async {
    try {
      final snap = await _col.where('vagaIdStr', isEqualTo: vagaIdStr).get();
      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('[CandidaturaRepo] listarPorVagaStr: $e');
      return [];
    }
  }

  // D7: try/catch — listarPorCandidatoStr retorna [] em caso de erro.
  @override
  Future<List<Candidatura>> listarPorCandidatoStr(String candidatoIdStr) async {
    try {
      final snap =
          await _col.where('candidatoIdStr', isEqualTo: candidatoIdStr).get();
      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('[CandidaturaRepo] listarPorCandidatoStr: $e');
      return [];
    }
  }

  // D7: try/catch — atualizarStatusStr não crasha o app.
  @override
  Future<void> atualizarStatusStr(String idStr, String status) async {
    try {
      await _col.doc(idStr).update({'status': status});
    } catch (e) {
      debugPrint('[CandidaturaRepo] atualizarStatusStr: $e');
    }
  }

  // D7: try/catch — atualizarScoreStr não crasha o app.
  @override
  Future<void> atualizarScoreStr(String idStr, double score) async {
    try {
      await _col.doc(idStr).update({'score': score});
    } catch (e) {
      debugPrint('[CandidaturaRepo] atualizarScoreStr: $e');
    }
  }

  @override
  Future<void> deletarStr(String idStr) async {
    try {
      await _col.doc(idStr).delete();
      debugPrint('[CandidaturaRepo] deletarStr: $idStr');
    } catch (e) {
      debugPrint('[CandidaturaRepo] deletarStr: $e');
    }
  }
}
