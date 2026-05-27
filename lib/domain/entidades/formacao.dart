// Entidade que representa uma formacao academica
class Formacao {
  // Construtor com campos obrigatorios e opcionais
  const Formacao({
    this.id,
    required this.candidatoId,
    required this.instituicao,
    required this.curso,
    required this.nivel,
    required this.dataInicio,
    this.dataFim,
    this.emAndamento = false,
  });

  final int? id;
  final int candidatoId;
  final String instituicao;
  final String curso;
  final String nivel;
  final String dataInicio;
  final String? dataFim;
  final bool emAndamento;

  // Cria a entidade a partir de um mapa serializado
  factory Formacao.fromMap(Map<String, dynamic> m) => Formacao(
        id: m['id'] as int?,
        candidatoId: m['candidato_id'] as int,
        instituicao: m['instituicao'] as String,
        curso: m['curso'] as String,
        nivel: m['nivel'] as String,
        dataInicio: m['data_inicio'] as String,
        dataFim: m['data_fim'] as String?,
        emAndamento: (m['em_andamento'] as int) == 1,
      );

  // Converte a entidade para persistencia
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'candidato_id': candidatoId,
        'instituicao': instituicao,
        'curso': curso,
        'nivel': nivel,
        'data_inicio': dataInicio,
        'data_fim': dataFim,
        'em_andamento': emAndamento ? 1 : 0,
      };

  // Cria uma copia com alteracoes pontuais
  Formacao copyWith({
    int? id,
    int? candidatoId,
    String? instituicao,
    String? curso,
    String? nivel,
    String? dataInicio,
    String? dataFim,
    bool? emAndamento,
  }) =>
      Formacao(
        id: id ?? this.id,
        candidatoId: candidatoId ?? this.candidatoId,
        instituicao: instituicao ?? this.instituicao,
        curso: curso ?? this.curso,
        nivel: nivel ?? this.nivel,
        dataInicio: dataInicio ?? this.dataInicio,
        dataFim: dataFim ?? this.dataFim,
        emAndamento: emAndamento ?? this.emAndamento,
      );

  @override
  // Ajuda em logs e depuracao
  String toString() =>
      'Formacao(id: $id, instituicao: $instituicao, curso: $curso, nivel: $nivel)';
}
