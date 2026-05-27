// Caso de uso para listar candidatos.
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';

class ListarCandidatos {
  // Repositorio injetado.
  const ListarCandidatos(this._repositorio);

  final ICandidatoRepositorio _repositorio;

  // Executa a listagem completa.
  Future<List<Candidato>> executar() => _repositorio.listarTodos();
}
