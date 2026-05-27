import 'package:rh_os/domain/entidades/vaga.dart';
import 'package:rh_os/domain/repositorios/i_vaga_repositorio.dart';

class SalvarVaga {
  const SalvarVaga(this._repositorio);

  final IVagaRepositorio _repositorio;

  Future<int> executar(Vaga vaga) => _repositorio.salvar(vaga);
}
