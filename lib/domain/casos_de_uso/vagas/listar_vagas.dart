// Caso de uso para listar vagas disponiveis
import 'package:rh_os/domain/entidades/vaga.dart';
import 'package:rh_os/domain/repositorios/i_vaga_repositorio.dart';

class ListarVagas {
  // Recebe o repositorio por injeção
  const ListarVagas(this._repositorio);

  // Repositorio de vagas
  final IVagaRepositorio _repositorio;

  // Executa a listagem de todas as vagas
  Future<List<Vaga>> executar() => _repositorio.listarTodas();
}
