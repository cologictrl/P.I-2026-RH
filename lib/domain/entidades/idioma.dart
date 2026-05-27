// Entidade que representa um idioma do candidato
class Idioma {
  // Construtor com campos obrigatorios e opcionais
  const Idioma({
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
  factory Idioma.fromMap(Map<String, dynamic> m) => Idioma(
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
  Idioma copyWith({
    int? id,
    int? candidatoId,
    String? nome,
    String? nivel,
  }) =>
      Idioma(
        id: id ?? this.id,
        candidatoId: candidatoId ?? this.candidatoId,
        nome: nome ?? this.nome,
        nivel: nivel ?? this.nivel,
      );

  @override
  // Ajuda em logs e depuracao
  String toString() => 'Idioma(id: $id, nome: $nome, nivel: $nivel)';
}
