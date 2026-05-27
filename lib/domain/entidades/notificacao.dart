class Notificacao {
  const Notificacao({
    this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensagem,
    this.lida = false,
    this.tipo,
    this.referenciaId,
    required this.criadoEm,
  });

  final int? id;
  final int usuarioId;
  final String titulo;
  final String mensagem;
  final bool lida;
  final String? tipo;
  final int? referenciaId;
  final String criadoEm;

  factory Notificacao.fromMap(Map<String, dynamic> m) => Notificacao(
        id: m['id'] as int?,
        usuarioId: m['usuario_id'] as int,
        titulo: m['titulo'] as String,
        mensagem: m['mensagem'] as String,
        lida: (m['lida'] as int) == 1,
        tipo: m['tipo'] as String?,
        referenciaId: m['referencia_id'] as int?,
        criadoEm: m['criado_em'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'usuario_id': usuarioId,
        'titulo': titulo,
        'mensagem': mensagem,
        'lida': lida ? 1 : 0,
        'tipo': tipo,
        'referencia_id': referenciaId,
        'criado_em': criadoEm,
      };

  Notificacao copyWith({bool? lida}) => Notificacao(
        id: id,
        usuarioId: usuarioId,
        titulo: titulo,
        mensagem: mensagem,
        lida: lida ?? this.lida,
        tipo: tipo,
        referenciaId: referenciaId,
        criadoEm: criadoEm,
      );

  @override
  String toString() => 'Notificacao(id: $id, titulo: $titulo, lida: $lida)';
}
