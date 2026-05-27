// Entidade que representa uma entrevista agendada no dominio
class Entrevista {
  final String? idStr;
  final String vagaIdStr;
  final String candidatoIdStr;
  final String dataHora;        // ISO 8601
  final String status;          // pendente | confirmada | cancelada | reagendar
  final String? observacoes;
  final String? vagaTitulo;     // desnormalizado para exibicao
  final String? candidatoNome;  // desnormalizado para exibicao
  final String? criadoEm;

  const Entrevista({
    this.idStr,
    required this.vagaIdStr,
    required this.candidatoIdStr,
    required this.dataHora,
    required this.status,
    this.observacoes,
    this.vagaTitulo,
    this.candidatoNome,
    this.criadoEm,
  });

  factory Entrevista.fromMap(Map<String, dynamic> m, {String? idStr}) =>
      Entrevista(
        idStr: idStr ?? m['idStr'] as String?,
        vagaIdStr: m['vagaIdStr'] as String,
        candidatoIdStr: m['candidatoIdStr'] as String,
        dataHora: m['dataHora'] as String,
        status: m['status'] as String? ?? 'pendente',
        observacoes: m['observacoes'] as String?,
        vagaTitulo: m['vagaTitulo'] as String?,
        candidatoNome: m['candidatoNome'] as String?,
        criadoEm: m['criado_em'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'vagaIdStr': vagaIdStr,
        'candidatoIdStr': candidatoIdStr,
        'dataHora': dataHora,
        'status': status,
        if (observacoes != null) 'observacoes': observacoes,
        if (vagaTitulo != null) 'vagaTitulo': vagaTitulo,
        if (candidatoNome != null) 'candidatoNome': candidatoNome,
        'criado_em': criadoEm ?? DateTime.now().toIso8601String(),
      };

  Entrevista copyWith({
    String? idStr,
    String? vagaIdStr,
    String? candidatoIdStr,
    String? dataHora,
    String? status,
    String? observacoes,
    String? vagaTitulo,
    String? candidatoNome,
  }) =>
      Entrevista(
        idStr: idStr ?? this.idStr,
        vagaIdStr: vagaIdStr ?? this.vagaIdStr,
        candidatoIdStr: candidatoIdStr ?? this.candidatoIdStr,
        dataHora: dataHora ?? this.dataHora,
        status: status ?? this.status,
        observacoes: observacoes ?? this.observacoes,
        vagaTitulo: vagaTitulo ?? this.vagaTitulo,
        candidatoNome: candidatoNome ?? this.candidatoNome,
        criadoEm: criadoEm,
      );
}
