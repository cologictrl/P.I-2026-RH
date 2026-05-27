import 'package:rh_os/domain/entidades/candidatura.dart';
import 'package:rh_os/domain/repositorios/i_candidatura_repositorio.dart';

class ListarCandidaturasPorVaga {
  const ListarCandidaturasPorVaga(this._repositorio);

  final ICandidaturaRepositorio _repositorio;

  Future<List<Candidatura>> executar(String vagaIdStr) =>
      _repositorio.listarPorVagaStr(vagaIdStr);
}
