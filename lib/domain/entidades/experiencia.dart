class Experiencia {
  const Experiencia({
    this.id,
    required this.candidatoId,
    required this.empresa,
    required this.cargo,
    this.descricao,
    required this.dataInicio,
    this.dataFim,
    this.atual = false,
  });

  final int? id;
  final int candidatoId;
  final String empresa;
  final String cargo;
  final String? descricao;
  final String dataInicio;
  final String? dataFim;
  final bool atual;

  factory Experiencia.fromMap(Map<String, dynamic> m) => Experiencia(
        id: m['id'] as int?,
        candidatoId: m['candidato_id'] as int,
        empresa: m['empresa'] as String,
        cargo: m['cargo'] as String,
        descricao: m['descricao'] as String?,
        dataInicio: m['data_inicio'] as String,
        dataFim: m['data_fim'] as String?,
        atual: (m['atual'] as int) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'candidato_id': candidatoId,
        'empresa': empresa,
        'cargo': cargo,
        'descricao': descricao,
        'data_inicio': dataInicio,
        'data_fim': dataFim,
        'atual': atual ? 1 : 0,
      };

  Experiencia copyWith({
    int? id,
    int? candidatoId,
    String? empresa,
    String? cargo,
    String? descricao,
    String? dataInicio,
    String? dataFim,
    bool? atual,
  }) =>
      Experiencia(
        id: id ?? this.id,
        candidatoId: candidatoId ?? this.candidatoId,
        empresa: empresa ?? this.empresa,
        cargo: cargo ?? this.cargo,
        descricao: descricao ?? this.descricao,
        dataInicio: dataInicio ?? this.dataInicio,
        dataFim: dataFim ?? this.dataFim,
        atual: atual ?? this.atual,
      );

  @override
  String toString() =>
      'Experiencia(id: $id, empresa: $empresa, cargo: $cargo, atual: $atual)';
}
