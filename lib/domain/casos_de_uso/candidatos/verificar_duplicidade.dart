import 'package:flutter/foundation.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';

class VerificarDuplicidade {
  final ICandidatoRepositorio _repo;
  VerificarDuplicidade(this._repo);

  Future<Candidato?> executar({String? cpf, String? email}) async {
    if (cpf != null && cpf.isNotEmpty) {
      final porCpf = await _repo.buscarPorCpf(cpf);
      if (porCpf != null) {
        debugPrint('[Duplicidade] Encontrado por CPF: $cpf');
        return porCpf;
      }
    }

    if (email != null && email.isNotEmpty) {
      final porEmail = await _repo.buscarPorEmail(email);
      if (porEmail != null) {
        debugPrint('[Duplicidade] Encontrado por e-mail: $email');
        return porEmail;
      }
    }

    return null;
  }
}
