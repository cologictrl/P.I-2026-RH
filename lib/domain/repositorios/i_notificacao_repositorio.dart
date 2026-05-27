import 'package:rh_os/domain/entidades/notificacao.dart';

abstract class INotificacaoRepositorio {
  Future<int> inserir(Notificacao notificacao);
  Future<int> marcarComoLida(int id);
  Future<int> marcarTodasComoLidas(int usuarioId);
  Future<int> deletar(int id);
  Future<List<Notificacao>> listarPorUsuario(int usuarioId);
  Future<List<Notificacao>> listarTodas();
  Future<int> contarNaoLidas(int usuarioId);
}
