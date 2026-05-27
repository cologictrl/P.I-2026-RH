// Serviço de auditoria: registra ações críticas dos usuários no Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AuditoriaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Registra uma ação auditável na coleção 'auditoria' do Firestore.
  /// [uid] — UID do usuário que realizou a ação.
  /// [acao] — identificador da ação (ex: 'login', 'upload_curriculo').
  /// [detalhes] — informação extra legível (ex: email, nome do candidato).
  Future<void> registrar({
    required String uid,
    required String acao,
    required String detalhes,
  }) async {
    try {
      await _db.collection('auditoria').add({
        'uid': uid,
        'acao': acao,
        'detalhes': detalhes,
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint('[Auditoria] $acao: $detalhes');
    } catch (e) {
      debugPrint('[Auditoria] Erro ao registrar: $e');
    }
  }
}
