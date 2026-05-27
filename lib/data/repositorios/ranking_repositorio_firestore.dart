// Repositório de rankings de candidatos por vaga no Firestore.
// ID do documento: vagaIdStr_candidatoIdStr (combinação única).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class RankingRepositorioFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _colecao = 'rankings';

  // Gera o ID do documento: vagaIdStr_candidatoIdStr
  String _docId(String vagaIdStr, String candidatoIdStr) =>
      '${vagaIdStr}_$candidatoIdStr';

  // Salvar ou atualizar ranking de um candidato para uma vaga.
  Future<void> salvar(
    String vagaIdStr,
    String candidatoIdStr,
    Map<String, dynamic> dados,
  ) async {
    try {
      final scores =
          (dados['scores_por_eixo'] as Map?)?.cast<String, dynamic>() ??
              (dados['scores'] as Map?)?.cast<String, dynamic>();
      final scoreTotal = (dados['score_total'] as num?)?.toDouble() ??
          (dados['score'] as num?)?.toDouble() ??
          0.0;
      await _db
          .collection(_colecao)
          .doc(_docId(vagaIdStr, candidatoIdStr))
          .set({
        'vagaIdStr': vagaIdStr,
        'candidatoIdStr': candidatoIdStr,
        'score': scoreTotal,
        'score_total': scoreTotal,
        if (scores != null) 'scores_por_eixo': scores,
        'gating_aprovado': dados['gating_aprovado'] ?? true,
        'requisitos_nao_atendidos': dados['requisitos_nao_atendidos'] ?? [],
        'justificativa': dados['justificativa'] ?? '',
        'pontos_fortes': dados['pontos_fortes'] ?? [],
        'pontos_fracos': dados['pontos_fracos'] ?? [],
        'calculado_em': DateTime.now().toIso8601String(),
      });
      debugPrint('[RankingRepo] Salvo: $vagaIdStr / $candidatoIdStr');
    } catch (e) {
      debugPrint('[RankingRepo] Erro ao salvar: $e');
    }
  }

  // Buscar ranking existente no cache do Firestore.
  // Retorna null se ainda não calculado.
  Future<Map<String, dynamic>?> buscar(
    String vagaIdStr,
    String candidatoIdStr,
  ) async {
    try {
      final doc = await _db
          .collection(_colecao)
          .doc(_docId(vagaIdStr, candidatoIdStr))
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('[RankingRepo] Erro ao buscar: $e');
      return null;
    }
  }

  // Listar todos os rankings de uma vaga ordenados por score decrescente.
  Future<List<Map<String, dynamic>>> listarPorVaga(String vagaIdStr) async {
    try {
      final snap = await _db
          .collection(_colecao)
          .where('vagaIdStr', isEqualTo: vagaIdStr)
          .orderBy('score', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[RankingRepo] Erro ao listar: $e');
      return [];
    }
  }

  // Apagar ranking de um candidato (usar quando candidato atualizar perfil).
  Future<void> apagar(String vagaIdStr, String candidatoIdStr) async {
    try {
      await _db
          .collection(_colecao)
          .doc(_docId(vagaIdStr, candidatoIdStr))
          .delete();
      debugPrint('[RankingRepo] Apagado: $vagaIdStr / $candidatoIdStr');
    } catch (e) {
      debugPrint('[RankingRepo] Erro ao apagar: $e');
    }
  }

  // Apagar todos os rankings de uma vaga (usar quando vaga for editada).
  Future<void> apagarPorVaga(String vagaIdStr) async {
    try {
      final snap = await _db
          .collection(_colecao)
          .where('vagaIdStr', isEqualTo: vagaIdStr)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
      debugPrint('[RankingRepo] Apagados por vaga: $vagaIdStr');
    } catch (e) {
      debugPrint('[RankingRepo] Erro ao apagar por vaga: $e');
    }
  }

  // Apagar todos os rankings de um candidato (usar quando perfil mudar).
  Future<void> apagarPorCandidato(String candidatoIdStr) async {
    try {
      final snap = await _db
          .collection(_colecao)
          .where('candidatoIdStr', isEqualTo: candidatoIdStr)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
      debugPrint('[RankingRepo] Apagados por candidato: $candidatoIdStr');
    } catch (e) {
      debugPrint('[RankingRepo] Erro ao apagar por candidato: $e');
    }
  }
}
