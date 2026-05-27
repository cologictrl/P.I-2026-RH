import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/entidades/experiencia.dart';
import 'package:rh_os/domain/entidades/formacao.dart';
import 'package:rh_os/domain/entidades/habilidade.dart';
import 'package:rh_os/domain/entidades/idioma.dart';

abstract class ICandidatoRepositorio {
  Future<int> salvar(Candidato candidato);
  Future<int> atualizar(Candidato candidato);
  Future<int> deletar(int id);
  Future<void> deletarPorIdStr(String idStr);
  Future<Candidato?> buscarPorId(int id);
  Future<Candidato?> buscarPorIdStr(String idStr);
  Future<Candidato?> buscarPorUsuarioId(int usuarioId);
  Future<Candidato?> buscarPorUsuarioUid(String uid);
  Future<Candidato?> buscarPorEmail(String email);
  Future<Candidato?> buscarPorCpf(String cpf);
  Future<List<Candidato>> listarTodos();
  Future<List<Candidato>> buscarPorNome(String termo);

  Future<int> salvarExperiencia(Experiencia e);
  Future<int> deletarExperiencia(int id);
  Future<List<Experiencia>> listarExperiencias(int candidatoId);
  Future<List<Experiencia>> listarExperienciasStr(String idStr);

  Future<int> salvarFormacao(Formacao f);
  Future<int> deletarFormacao(int id);
  Future<List<Formacao>> listarFormacoes(int candidatoId);
  Future<List<Formacao>> listarFormacoesStr(String idStr);

  Future<int> salvarHabilidade(Habilidade h);
  Future<int> deletarHabilidade(int id);
  Future<List<Habilidade>> listarHabilidades(int candidatoId);
  Future<List<Habilidade>> listarHabilidadesStr(String idStr);

  Future<int> salvarIdioma(Idioma i);
  Future<int> deletarIdioma(int id);
  Future<List<Idioma>> listarIdiomas(int candidatoId);
  Future<List<Idioma>> listarIdiomasStr(String idStr);

  Future<int> contarTotal();
  Future<int> atualizarCampo(int id, String campo, String valor);
  Future<void> atualizarCampoStr(String idStr, String campo, String valor);
  Future<List<Map<String, dynamic>>> listarTopHabilidades(int limite);

  Future<String> salvarCompleto(
    Candidato candidato, {
    List<Map<String, dynamic>> experiencias = const [],
    List<Map<String, dynamic>> formacoes = const [],
    List<String> habilidades = const [],
    List<Map<String, dynamic>> idiomas = const [],
    int camposPreenchidos = 0,
    int totalCampos = 12,
    String origemExtracao = 'desconhecido',
  });
}
