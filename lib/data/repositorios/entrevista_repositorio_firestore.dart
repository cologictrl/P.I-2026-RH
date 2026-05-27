// Repositorio de entrevistas no Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:rh_os/domain/entidades/entrevista.dart';

class EntrevistaRepositorioFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _colecao = 'entrevistas';

  // Salva uma entrevista nova (add) ou existente (set pelo idStr).
  Future<String?> salvar(Entrevista entrevista) async {
    try {
      if (entrevista.idStr != null) {
        await _db
            .collection(_colecao)
            .doc(entrevista.idStr)
            .set(entrevista.toMap());
        return entrevista.idStr;
      }
      final ref = await _db.collection(_colecao).add(entrevista.toMap());
      debugPrint('[EntrevistaRepo] Criada: ${ref.id}');
      return ref.id;
    } catch (e) {
      debugPrint('[EntrevistaRepo] Erro ao salvar: $e');
      return null;
    }
  }

  // Lista todas as entrevistas ordenadas por data (para admin/recrutador).
  Future<List<Entrevista>> listarTodas() async {
    try {
      final snap = await _db
          .collection(_colecao)
          .orderBy('dataHora', descending: false)
          .get();
      return snap.docs
          .map((d) => Entrevista.fromMap(d.data(), idStr: d.id))
          .toList();
    } catch (e) {
      debugPrint('[EntrevistaRepo] Erro ao listar todas: $e');
      return [];
    }
  }

  // Lista entrevistas de uma vaga especifica.
  Future<List<Entrevista>> listarPorVaga(String vagaIdStr) async {
    try {
      final snap = await _db
          .collection(_colecao)
          .where('vagaIdStr', isEqualTo: vagaIdStr)
          .orderBy('dataHora', descending: false)
          .get();
      return snap.docs
          .map((d) => Entrevista.fromMap(d.data(), idStr: d.id))
          .toList();
    } catch (e) {
      debugPrint('[EntrevistaRepo] Erro ao listar por vaga: $e');
      return [];
    }
  }

  // Lista entrevistas de um candidato pelo idStr do documento Firestore.
  Future<List<Entrevista>> listarPorCandidato(String candidatoIdStr) async {
    try {
      final snap = await _db
          .collection(_colecao)
          .where('candidatoIdStr', isEqualTo: candidatoIdStr)
          .orderBy('dataHora', descending: false)
          .get();
      return snap.docs
          .map((d) => Entrevista.fromMap(d.data(), idStr: d.id))
          .toList();
    } catch (e) {
      debugPrint('[EntrevistaRepo] Erro ao listar por candidato: $e');
      return [];
    }
  }

  // Atualiza apenas o status da entrevista.
  Future<void> atualizarStatus(String idStr, String status) async {
    try {
      await _db.collection(_colecao).doc(idStr).update({'status': status});
      debugPrint('[EntrevistaRepo] Status atualizado: $idStr → $status');
    } catch (e) {
      debugPrint('[EntrevistaRepo] Erro ao atualizar status: $e');
    }
  }

  // Reagenda: atualiza dataHora e volta status para pendente.
  Future<void> reagendar(String idStr, String novaDataHora) async {
    try {
      await _db.collection(_colecao).doc(idStr).update({
        'dataHora': novaDataHora,
        'status': 'pendente',
      });
      debugPrint('[EntrevistaRepo] Reagendada: $idStr');
    } catch (e) {
      debugPrint('[EntrevistaRepo] Erro ao reagendar: $e');
    }
  }

  // Remove uma entrevista pelo id do documento.
  Future<void> deletar(String idStr) async {
    try {
      await _db.collection(_colecao).doc(idStr).delete();
      debugPrint('[EntrevistaRepo] Deletada: $idStr');
    } catch (e) {
      debugPrint('[EntrevistaRepo] Erro ao deletar: $e');
    }
  }
}
