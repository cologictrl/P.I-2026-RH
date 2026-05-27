// Repositorio de usuarios no Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rh_os/domain/entidades/usuario.dart';
import 'package:rh_os/domain/repositorios/i_usuario_repositorio.dart';

class UsuarioRepositorioFirestore implements IUsuarioRepositorio {
  // Instancias base.
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _colecao = 'usuarios';

  @override
  Future<Usuario?> autenticar(String email, String senhaHash) async => null;

  @override
  Future<Usuario?> buscarPorId(int id) async => null;

  @override
  Future<Usuario?> buscarPorEmail(String email) async {
    // Busca por e-mail com limite de um resultado.
    final snap = await _db
        .collection(_colecao)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _docToUsuario(snap.docs.first);
  }

  Future<Usuario?> buscarPorUid(String uid) async {
    // Busca documento diretamente pelo UID.
    final doc = await _db.collection(_colecao).doc(uid).get();
    if (!doc.exists) return null;
    return _docToUsuario(doc);
  }

  @override
  Future<List<Usuario>> listarTodos() async {
    // Carrega todos os documentos da colecao.
    final snap = await _db.collection(_colecao).get();
    return snap.docs.map(_docToUsuario).toList();
  }

  @override
  Future<List<Usuario>> listarAtivos() async {
    // Filtra apenas usuarios ativos.
    final snap =
        await _db.collection(_colecao).where('ativo', isEqualTo: true).get();
    return snap.docs.map(_docToUsuario).toList();
  }

  @override
  Future<int> salvar(Usuario usuario) async {
    // Usa o UID autenticado como chave do documento.
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;
    await _db.collection(_colecao).doc(uid).set(_toMap(usuario));
    return 0;
  }

  @override
  Future<int> atualizar(Usuario usuario) async {
    // Atualiza o documento do usuario autenticado.
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;
    await _db.collection(_colecao).doc(uid).update(_toMap(usuario));
    return 0;
  }

  @override
  Future<int> deletar(int id) async => 0;

  @override
  Future<int> atualizarAtivo(int id, bool ativo) async => 0;

  Future<void> atualizarAtivoStr(String uid, bool ativo) async {
    // Atualiza apenas o campo de status ativo.
    await _db.collection(_colecao).doc(uid).update({'ativo': ativo});
  }

  Usuario _docToUsuario(DocumentSnapshot<Map<String, dynamic>> doc) {
    // Converte documento para entidade de dominio.
    final d = doc.data()!;
    return Usuario(
      nome: d['nome'] as String? ?? '',
      email: d['email'] as String? ?? '',
      senhaHash: d['senha_hash'] as String? ?? '',
      perfil: d['perfil'] as String? ?? 'colaborador',
      ativo:
          d['ativo'] is bool ? d['ativo'] as bool : (d['ativo'] as int?) == 1,
      criadoEm: d['criado_em'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> _toMap(Usuario u) => {
        // Serializa entidade para persistencia.
        'nome': u.nome,
        'email': u.email,
        'senha_hash': u.senhaHash,
        'perfil': u.perfil,
        'ativo': u.ativo,
        'criado_em': u.criadoEm,
      };
}
