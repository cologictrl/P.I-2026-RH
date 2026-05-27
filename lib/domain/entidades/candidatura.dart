class Candidatura {
  const Candidatura({
    this.id,
    this.idStr,
    required this.candidatoId,
    required this.vagaId,
    this.candidatoIdStr,
    this.vagaIdStr,
    this.status = 'pendente',
    this.nota,
    required this.dataCandidatura,
    required this.atualizadoEm,
  });

  final int? id;
  final String? idStr;
  final int candidatoId;
  final int vagaId;
  final String? candidatoIdStr;
  final String? vagaIdStr;
  final String status;
  final double? nota;
  final String dataCandidatura;
  final String atualizadoEm;

  factory Candidatura.fromMap(Map<String, dynamic> m) => Candidatura(
        id: m['id'] as int?,
        idStr: m['idStr'] as String?,
        candidatoId: (m['candidato_id'] as int?) ?? 0,
        vagaId: (m['vaga_id'] as int?) ?? 0,
        candidatoIdStr: m['candidatoIdStr'] as String?,
        vagaIdStr: m['vagaIdStr'] as String?,
        status: m['status'] as String? ?? 'pendente',
        nota: (m['nota'] as num?)?.toDouble(),
        dataCandidatura: m['data_candidatura'] as String,
        atualizadoEm: m['atualizado_em'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (idStr != null) 'idStr': idStr,
        'candidato_id': candidatoId,
        'vaga_id': vagaId,
        if (candidatoIdStr != null) 'candidatoIdStr': candidatoIdStr,
        if (vagaIdStr != null) 'vagaIdStr': vagaIdStr,
        'status': status,
        'nota': nota,
        'data_candidatura': dataCandidatura,
        'atualizado_em': atualizadoEm,
      };

  Candidatura copyWith({
    int? id,
    String? idStr,
    int? candidatoId,
    int? vagaId,
    String? candidatoIdStr,
    String? vagaIdStr,
    String? status,
    double? nota,
    String? dataCandidatura,
    String? atualizadoEm,
  }) =>
      Candidatura(
        id: id ?? this.id,
        idStr: idStr ?? this.idStr,
        candidatoId: candidatoId ?? this.candidatoId,
        vagaId: vagaId ?? this.vagaId,
        candidatoIdStr: candidatoIdStr ?? this.candidatoIdStr,
        vagaIdStr: vagaIdStr ?? this.vagaIdStr,
        status: status ?? this.status,
        nota: nota ?? this.nota,
        dataCandidatura: dataCandidatura ?? this.dataCandidatura,
        atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      );

  @override
  String toString() =>
      'Candidatura(id: $id, idStr: $idStr, candidatoId: $candidatoId, '
      'vagaId: $vagaId, status: $status)';
}
