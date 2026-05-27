// Rotas nomeadas usadas pelo GoRouter.

abstract class AppRotas {
  static const String login = '/login';
  static const String home = '/home';
  static const String mais = '/mais';
  static const String notificacoes = '/notificacoes';
  static const String perfil = '/perfil';
  static const String editarCampo = '/perfil/editar';
  static const String curriculos = '/curriculos';
  static const String curriculoCompleto = '/curriculos/:id';
  static const String upload = '/upload';
  static const String vagas = '/vagas';
  static const String novaVaga = '/vagas/nova';
  static const String detalheVaga = '/vagas/:id';
  static const String dashboard = '/dashboard';
  static const String admin = '/admin';
  static const String entrevistas = '/entrevistas';

  static String curriculoCompletoId(String id) => '/curriculos/$id';
  // Usa idStr (String) como identificador principal das vagas.
  static String detalheVagaId(String idStr) => '/vagas/$idStr';
}
