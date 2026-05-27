import 'package:rh_os/domain/entidades/vaga.dart';

abstract class IVagaRepositorio {
  Future<int> salvar(Vaga vaga);
  Future<int> atualizar(Vaga vaga);
  Future<int> deletar(int id);
  Future<Vaga?> buscarPorId(int id);
  Future<void> deletarPorIdStr(String idStr);
  Future<Vaga?> buscarPorIdStr(String idStr);
  Future<List<Vaga>> listarTodas();
  Future<List<Vaga>> listarPorStatus(String status);
  Future<List<Vaga>> buscarPorTitulo(String termo);
  Future<int> contarPorStatus(String status);
  Future<void> atualizarStatus(int id, String status);
  Future<void> atualizarStatusStr(String idStr, String status);
}
