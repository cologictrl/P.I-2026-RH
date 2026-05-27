import 'package:rh_os/domain/entidades/candidatura.dart';

abstract class ICandidaturaRepositorio {
  Future<int> salvar(Candidatura candidatura);
  Future<int> atualizar(Candidatura candidatura);
  Future<int> atualizarStatus(int id, String status);
  Future<void> atualizarStatusStr(String idStr, String status);
  Future<int> atualizarNota(int id, double nota);
  Future<int> deletar(int id);
  Future<void> deletarStr(String idStr);
  Future<Candidatura?> buscarPorId(int id);
  Future<List<Candidatura>> listarPorVaga(int vagaId);
  Future<List<Candidatura>> listarPorVagaStr(String vagaIdStr);
  Future<List<Candidatura>> listarPorCandidato(int candidatoId);
  Future<List<Candidatura>> listarPorCandidatoStr(String candidatoIdStr);
  Future<bool> existeCandidatura(int candidatoId, int vagaId);
  Future<Map<String, int>> contarPorStatus(int vagaId);
  Future<Map<String, int>> contarTodosPorStatus();
  Future<int> contarPorVaga(int vagaId);
  Future<void> atualizarScore(int id, double score);
  Future<void> atualizarScoreStr(String idStr, double score);
}
