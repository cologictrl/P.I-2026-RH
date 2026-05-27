// Entidade que representa uma habilidade do candidato
class Habilidade {
  // Construtor com campos obrigatorios e opcionais
  const Habilidade({
    this.id,
    required this.candidatoId,
    required this.nome,
    required this.nivel,
  });

  final int? id;
  final int candidatoId;
  final String nome;
  final String nivel;

  // Cria a entidade a partir de um mapa serializado
  factory Habilidade.fromMap(Map<String, dynamic> m) => Habilidade(
        id: m['id'] as int?,
        candidatoId: m['candidato_id'] as int,
        nome: m['nome'] as String,
        nivel: m['nivel'] as String,
      );

  // Converte a entidade para persistencia
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'candidato_id': candidatoId,
        'nome': nome,
        'nivel': nivel,
      };

  // Cria uma copia com alteracoes pontuais
  Habilidade copyWith({
    int? id,
    int? candidatoId,
    String? nome,
    String? nivel,
  }) =>
      Habilidade(
        id: id ?? this.id,
        candidatoId: candidatoId ?? this.candidatoId,
        nome: nome ?? this.nome,
        nivel: nivel ?? this.nivel,
      );

  @override
  // Ajuda em logs e depuracao
  String toString() => 'Habilidade(id: $id, nome: $nome, nivel: $nivel)';
}
