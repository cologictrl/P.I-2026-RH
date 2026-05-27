import 'package:rh_os/domain/entidades/notificacao.dart';
import 'package:rh_os/domain/repositorios/i_notificacao_repositorio.dart';

class NotificacaoRepositorioFirestore implements INotificacaoRepositorio {
  // Implementacao pendente (Firestore).
  @override
  Future<int> inserir(Notificacao notificacao) async => 0;

  @override
  Future<int> marcarComoLida(int id) async => 0;

  @override
  Future<int> marcarTodasComoLidas(int usuarioId) async => 0;

  @override
  Future<int> deletar(int id) async => 0;

  @override
  Future<List<Notificacao>> listarPorUsuario(int usuarioId) async => [];

  @override
  Future<List<Notificacao>> listarTodas() async => [];

  @override
  Future<int> contarNaoLidas(int usuarioId) async => 0;
}
