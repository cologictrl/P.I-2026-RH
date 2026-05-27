import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';

class DeletarCandidato {
  // Remove candidato por id.
  const DeletarCandidato(this._repositorio);

  final ICandidatoRepositorio _repositorio;

  Future<void> executar(String idStr) => _repositorio.deletarPorIdStr(idStr);
}
