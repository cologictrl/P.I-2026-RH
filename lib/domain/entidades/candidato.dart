// Entidade que representa um candidato no dominio
class Candidato {
  // Construtor da entidade com campos obrigatorios e opcionais
  const Candidato({
    this.id,
    this.idStr,
    this.usuarioId,
    this.usuarioUid,
    required this.nome,
    this.cpf,
    this.email,
    this.telefone,
    this.dataNascimento,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    this.resumo,
    this.fotoPath,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  final int? id;
  final String? idStr;
  final int? usuarioId;
  final String? usuarioUid;
  final String nome;
  final String? cpf;
  final String? email;
  final String? telefone;
  final String? dataNascimento;
  final String? logradouro;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? cep;
  final String? resumo;
  final String? fotoPath;
  final String criadoEm;
  final String atualizadoEm;

  // Cria a entidade a partir de um mapa serializado
  factory Candidato.fromMap(Map<String, dynamic> m) => Candidato(
        id: m['id'] as int?,
        idStr: m['idStr'] as String?,
        usuarioId: m['usuario_id'] as int?,
        usuarioUid: m['usuario_uid'] as String?,
        nome: m['nome'] as String,
        cpf: m['cpf'] as String?,
        email: m['email'] as String?,
        telefone: m['telefone'] as String?,
        dataNascimento: m['data_nascimento'] as String?,
        logradouro: m['logradouro'] as String?,
        numero: m['numero'] as String?,
        complemento: m['complemento'] as String?,
        bairro: m['bairro'] as String?,
        cidade: m['cidade'] as String?,
        estado: m['estado'] as String?,
        cep: m['cep'] as String?,
        resumo: m['resumo'] as String?,
        fotoPath: m['foto_path'] as String?,
        criadoEm: m['criado_em'] as String,
        atualizadoEm: m['atualizado_em'] as String,
      );

  // Converte a entidade para um mapa pronto para persistencia
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (idStr != null) 'idStr': idStr,
        'usuario_id': usuarioId,
        'usuario_uid': usuarioUid,
        'nome': nome,
        'cpf': cpf,
        'email': email,
        'telefone': telefone,
        'data_nascimento': dataNascimento,
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'cep': cep,
        'resumo': resumo,
        'foto_path': fotoPath,
        'criado_em': criadoEm,
        'atualizado_em': atualizadoEm,
      };

  // Cria uma copia da entidade com atualizacoes pontuais
  Candidato copyWith({
    int? id,
    String? idStr,
    int? usuarioId,
    String? usuarioUid,
    String? nome,
    String? cpf,
    String? email,
    String? telefone,
    String? dataNascimento,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
    String? cep,
    String? resumo,
    String? fotoPath,
    String? criadoEm,
    String? atualizadoEm,
  }) =>
      Candidato(
        id: id ?? this.id,
        idStr: idStr ?? this.idStr,
        usuarioId: usuarioId ?? this.usuarioId,
        usuarioUid: usuarioUid ?? this.usuarioUid,
        nome: nome ?? this.nome,
        cpf: cpf ?? this.cpf,
        email: email ?? this.email,
        telefone: telefone ?? this.telefone,
        dataNascimento: dataNascimento ?? this.dataNascimento,
        logradouro: logradouro ?? this.logradouro,
        numero: numero ?? this.numero,
        complemento: complemento ?? this.complemento,
        bairro: bairro ?? this.bairro,
        cidade: cidade ?? this.cidade,
        estado: estado ?? this.estado,
        cep: cep ?? this.cep,
        resumo: resumo ?? this.resumo,
        fotoPath: fotoPath ?? this.fotoPath,
        criadoEm: criadoEm ?? this.criadoEm,
        atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      );

  @override
  // Facilita depuracao e logs da entidade
  String toString() =>
      'Candidato(id: $id, nome: $nome, cidade: $cidade, estado: $estado)';
}
