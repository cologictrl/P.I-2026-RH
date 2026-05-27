// Testes unitários para a entidade Entrevista.
// Cobre: fromMap, toMap, copyWith e status padrão.
import 'package:flutter_test/flutter_test.dart';
import 'package:rh_os/domain/entidades/entrevista.dart';

void main() {
  const dataHora = '2024-06-15T10:00:00.000Z';
  const criadoEm = '2024-06-10T08:00:00.000Z';

  final mapaCompleto = {
    'vagaIdStr': 'vaga-123',
    'candidatoIdStr': 'cand-456',
    'dataHora': dataHora,
    'status': 'confirmada',
    'observacoes': 'Trazer portfólio',
    'vagaTitulo': 'Dev Flutter',
    'candidatoNome': 'João Silva',
    'criado_em': criadoEm,
  };

  // ── fromMap ────────────────────────────────────────────────────────────────

  group('Entrevista.fromMap', () {
    test('preenche todos os campos corretamente', () {
      final e = Entrevista.fromMap(mapaCompleto, idStr: 'ent-789');

      expect(e.idStr, 'ent-789');
      expect(e.vagaIdStr, 'vaga-123');
      expect(e.candidatoIdStr, 'cand-456');
      expect(e.dataHora, dataHora);
      expect(e.status, 'confirmada');
      expect(e.observacoes, 'Trazer portfólio');
      expect(e.vagaTitulo, 'Dev Flutter');
      expect(e.candidatoNome, 'João Silva');
      expect(e.criadoEm, criadoEm);
    });

    test('status padrão é "pendente" quando ausente no mapa', () {
      final mapa = Map<String, dynamic>.from(mapaCompleto)
        ..remove('status');

      final e = Entrevista.fromMap(mapa);

      expect(e.status, 'pendente');
    });

    test('idStr pode vir do mapa quando não informado no parâmetro', () {
      final mapa = Map<String, dynamic>.from(mapaCompleto)
        ..['idStr'] = 'ent-do-mapa';

      final e = Entrevista.fromMap(mapa);

      expect(e.idStr, 'ent-do-mapa');
    });
  });

  // ── toMap ──────────────────────────────────────────────────────────────────

  group('Entrevista.toMap', () {
    test('serializa todos os campos obrigatórios', () {
      const e = Entrevista(
        vagaIdStr: 'vaga-123',
        candidatoIdStr: 'cand-456',
        dataHora: dataHora,
        status: 'pendente',
      );

      final m = e.toMap();

      expect(m['vagaIdStr'], 'vaga-123');
      expect(m['candidatoIdStr'], 'cand-456');
      expect(m['dataHora'], dataHora);
      expect(m['status'], 'pendente');
    });

    test('inclui campos opcionais apenas quando não nulos', () {
      const e = Entrevista(
        vagaIdStr: 'v',
        candidatoIdStr: 'c',
        dataHora: dataHora,
        status: 'pendente',
        observacoes: 'Obs aqui',
        vagaTitulo: 'Título',
        candidatoNome: 'Nome',
      );

      final m = e.toMap();

      expect(m.containsKey('observacoes'), isTrue);
      expect(m['observacoes'], 'Obs aqui');
      expect(m.containsKey('vagaTitulo'), isTrue);
      expect(m.containsKey('candidatoNome'), isTrue);
    });

    test('omite campos opcionais quando nulos', () {
      const e = Entrevista(
        vagaIdStr: 'v',
        candidatoIdStr: 'c',
        dataHora: dataHora,
        status: 'pendente',
      );

      final m = e.toMap();

      expect(m.containsKey('observacoes'), isFalse);
      expect(m.containsKey('vagaTitulo'), isFalse);
      expect(m.containsKey('candidatoNome'), isFalse);
    });
  });

  // ── copyWith ───────────────────────────────────────────────────────────────

  group('Entrevista.copyWith', () {
    const original = Entrevista(
      idStr: 'ent-1',
      vagaIdStr: 'vaga-1',
      candidatoIdStr: 'cand-1',
      dataHora: dataHora,
      status: 'pendente',
      observacoes: 'Original',
    );

    test('altera apenas o status, mantendo os demais campos', () {
      final copia = original.copyWith(status: 'confirmada');

      expect(copia.status, 'confirmada');
      expect(copia.idStr, original.idStr);
      expect(copia.vagaIdStr, original.vagaIdStr);
      expect(copia.candidatoIdStr, original.candidatoIdStr);
      expect(copia.dataHora, original.dataHora);
      expect(copia.observacoes, original.observacoes);
    });

    test('altera dataHora mantendo o status', () {
      const novaData = '2024-07-20T14:00:00.000Z';
      final copia = original.copyWith(dataHora: novaData);

      expect(copia.dataHora, novaData);
      expect(copia.status, original.status);
    });

    test('sem argumentos retorna cópia idêntica', () {
      final copia = original.copyWith();

      expect(copia.idStr, original.idStr);
      expect(copia.vagaIdStr, original.vagaIdStr);
      expect(copia.status, original.status);
      expect(copia.observacoes, original.observacoes);
    });
  });

  // ── status padrão ──────────────────────────────────────────────────────────

  group('status padrão', () {
    test('entrevista criada sem status explícito via fromMap usa "pendente"', () {
      final e = Entrevista.fromMap({
        'vagaIdStr': 'v',
        'candidatoIdStr': 'c',
        'dataHora': dataHora,
        // 'status' ausente intencionalmente
      });

      expect(e.status, 'pendente');
    });
  });
}
