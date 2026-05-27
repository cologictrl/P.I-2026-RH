// Entidade que representa um usuario no dominio
class Usuario {
  // Construtor com campos obrigatorios e opcionais
  const Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.senhaHash,
    required this.perfil,
    this.ativo = true,
    required this.criadoEm,
  });

  final int? id;
  final String nome;
  final String email;
  final String senhaHash;
  final String perfil;
  final bool ativo;
  final String criadoEm;

  // Cria a entidade a partir de um mapa serializado
  factory Usuario.fromMap(Map<String, dynamic> m) => Usuario(
        id: m['id'] as int?,
        nome: m['nome'] as String? ?? '',
        email: m['email'] as String? ?? '',
        senhaHash: m['senha_hash'] as String? ?? '',
        perfil: m['perfil'] as String? ?? 'colaborador',
        ativo:
            m['ativo'] is bool ? m['ativo'] as bool : (m['ativo'] as int?) == 1,
        criadoEm: m['criado_em'] as String? ?? DateTime.now().toIso8601String(),
      );

  // Converte a entidade para persistencia
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nome': nome,
        'email': email,
        'senha_hash': senhaHash,
        'perfil': perfil,
        'ativo': ativo ? 1 : 0,
        'criado_em': criadoEm,
      };

  // Cria uma copia com alteracoes pontuais
  Usuario copyWith({
    int? id,
    String? nome,
    String? email,
    String? senhaHash,
    String? perfil,
    bool? ativo,
    String? criadoEm,
  }) =>
      Usuario(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        email: email ?? this.email,
        senhaHash: senhaHash ?? this.senhaHash,
        perfil: perfil ?? this.perfil,
        ativo: ativo ?? this.ativo,
        criadoEm: criadoEm ?? this.criadoEm,
      );

  @override
  // Ajuda em logs e depuracao
  String toString() =>
      'Usuario(id: $id, nome: $nome, email: $email, perfil: $perfil, ativo: $ativo)';
}
