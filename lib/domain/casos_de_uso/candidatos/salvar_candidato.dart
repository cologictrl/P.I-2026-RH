import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';

class SalvarCandidato {
  const SalvarCandidato(this._repositorio);

  final ICandidatoRepositorio _repositorio;

  Future<int> executar(Candidato candidato) => _repositorio.salvar(candidato);
}
