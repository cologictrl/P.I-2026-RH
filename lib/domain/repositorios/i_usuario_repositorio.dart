// Contrato de acesso aos usuarios no dominio
import 'package:rh_os/domain/entidades/usuario.dart';

abstract class IUsuarioRepositorio {
  // Persiste um novo usuario
  Future<int> salvar(Usuario usuario);
  // Atualiza um usuario existente
  Future<int> atualizar(Usuario usuario);
  // Remove um usuario pelo identificador numerico
  Future<int> deletar(int id);
  // Busca um usuario pelo identificador numerico
  Future<Usuario?> buscarPorId(int id);
  // Busca um usuario pelo e-mail
  Future<Usuario?> buscarPorEmail(String email);
  // Lista todos os usuarios
  Future<List<Usuario>> listarTodos();
  // Lista apenas usuarios ativos
  Future<List<Usuario>> listarAtivos();
  // Executa autenticacao persistida no repositorio
  Future<Usuario?> autenticar(String email, String senhaHash);
  // Atualiza o status de ativo do usuario
  Future<int> atualizarAtivo(int id, bool ativo);
}
