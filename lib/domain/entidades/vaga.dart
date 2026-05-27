// Entidade que representa uma vaga no dominio
class Vaga {
  // Construtor com campos obrigatorios e opcionais
  const Vaga({
    this.id,
    this.idStr,
    required this.titulo,
    required this.descricao,
    this.requisitos,
    this.local,
    this.tipoContrato,
    this.salario,
    this.status = 'aberta',
    this.criadoPor,
    required this.criadoEm,
    required this.atualizadoEm,
    // V1 — campos estruturados
    this.senioridade,
    this.modalidade,
    this.salarioMin,
    this.salarioMax,
    this.habilidades,
    this.softSkills,
  });

  final int? id;
  final String? idStr;
  final String titulo;
  final String descricao;
  final String? requisitos;
  final String? local;         // ex: 'São Paulo - SP'
  final String? tipoContrato;
  final String? salario;       // legado — preferir salarioMin/salarioMax
  final String status;
  final int? criadoPor;
  final String criadoEm;
  final String atualizadoEm;
  // V1 — novos campos estruturados
  final String? senioridade;         // 'junior' | 'pleno' | 'senior' | 'especialista'
  final String? modalidade;          // 'presencial' | 'remoto' | 'hibrido'
  final double? salarioMin;
  final double? salarioMax;
  final List<String>? habilidades;   // hard skills tecnicas
  final List<String>? softSkills;    // soft skills comportamentais

  // Cria a entidade a partir de um mapa serializado
  factory Vaga.fromMap(Map<String, dynamic> m) => Vaga(
        id: m['id'] as int?,
        idStr: m['idStr'] as String?,
        titulo: m['titulo'] as String,
        descricao: m['descricao'] as String,
        requisitos: m['requisitos'] as String?,
        local: m['local'] as String?,
        tipoContrato: m['tipo_contrato'] as String?,
        salario: m['salario'] as String?,
        status: m['status'] as String? ?? 'aberta',
        criadoPor: m['criado_por'] as int?,
        criadoEm: m['criado_em'] as String,
        atualizadoEm: m['atualizado_em'] as String,
        senioridade: m['senioridade'] as String?,
        modalidade: m['modalidade'] as String?,
        salarioMin: (m['salario_min'] as num?)?.toDouble(),
        salarioMax: (m['salario_max'] as num?)?.toDouble(),
        habilidades: (m['habilidades'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        softSkills: (m['soft_skills'] as List?)
            ?.map((e) => e.toString())
            .toList(),
      );

  // Converte a entidade para persistencia
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (idStr != null) 'idStr': idStr,
        'titulo': titulo,
        'descricao': descricao,
        'requisitos': requisitos,
        'local': local,
        'tipo_contrato': tipoContrato,
        'salario': salario,
        'status': status,
        'criado_por': criadoPor,
        'criado_em': criadoEm,
        'atualizado_em': atualizadoEm,
        if (senioridade != null) 'senioridade': senioridade,
        if (modalidade != null) 'modalidade': modalidade,
        if (salarioMin != null) 'salario_min': salarioMin,
        if (salarioMax != null) 'salario_max': salarioMax,
        if (habilidades != null) 'habilidades': habilidades,
        if (softSkills != null) 'soft_skills': softSkills,
      };

  // Cria uma copia com alteracoes pontuais
  Vaga copyWith({
    int? id,
    String? idStr,
    String? titulo,
    String? descricao,
    String? requisitos,
    String? local,
    String? tipoContrato,
    String? salario,
    String? status,
    int? criadoPor,
    String? criadoEm,
    String? atualizadoEm,
    String? senioridade,
    String? modalidade,
    double? salarioMin,
    double? salarioMax,
    List<String>? habilidades,
    List<String>? softSkills,
  }) =>
      Vaga(
        id: id ?? this.id,
        idStr: idStr ?? this.idStr,
        titulo: titulo ?? this.titulo,
        descricao: descricao ?? this.descricao,
        requisitos: requisitos ?? this.requisitos,
        local: local ?? this.local,
        tipoContrato: tipoContrato ?? this.tipoContrato,
        salario: salario ?? this.salario,
        status: status ?? this.status,
        criadoPor: criadoPor ?? this.criadoPor,
        criadoEm: criadoEm ?? this.criadoEm,
        atualizadoEm: atualizadoEm ?? this.atualizadoEm,
        senioridade: senioridade ?? this.senioridade,
        modalidade: modalidade ?? this.modalidade,
        salarioMin: salarioMin ?? this.salarioMin,
        salarioMax: salarioMax ?? this.salarioMax,
        habilidades: habilidades ?? this.habilidades,
        softSkills: softSkills ?? this.softSkills,
      );

  @override
  // Ajuda em logs e depuracao
  String toString() =>
      'Vaga(id: $id, idStr: $idStr, titulo: $titulo, status: $status, '
      'senioridade: $senioridade, modalidade: $modalidade, local: $local)';
}
