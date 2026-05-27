// Testes unitários para a entidade Vaga.
// Cobre: fromMap com novos campos (V1), toMap, copyWith.
import 'package:flutter_test/flutter_test.dart';
import 'package:rh_os/domain/entidades/vaga.dart';

void main() {
  const criadoEm = '2024-01-01T00:00:00.000Z';
  const atualizadoEm = '2024-01-02T00:00:00.000Z';

  final mapaCompleto = <String, dynamic>{
    'titulo': 'Desenvolvedor Flutter Sênior',
    'descricao': 'Vaga para dev Flutter com experiência em Clean Architecture',
    'requisitos': 'Flutter, Dart, Firebase',
    'status': 'aberta',
    'criado_em': criadoEm,
    'atualizado_em': atualizadoEm,
    // V1 — novos campos estruturados
    'senioridade': 'senior',
    'modalidade': 'hibrido',
    'salario_min': 8000.0,
    'salario_max': 15000.0,
    'habilidades': ['Flutter', 'Dart', 'Firebase', 'Git'],
    'soft_skills': ['Comunicação', 'Proatividade'],
  };

  // ── fromMap com novos campos ───────────────────────────────────────────────

  group('Vaga.fromMap — campos V1', () {
    test('preenche senioridade corretamente', () {
      final v = Vaga.fromMap(mapaCompleto);
      expect(v.senioridade, 'senior');
    });

    test('preenche modalidade corretamente', () {
      final v = Vaga.fromMap(mapaCompleto);
      expect(v.modalidade, 'hibrido');
    });

    test('preenche salarioMin e salarioMax corretamente', () {
      final v = Vaga.fromMap(mapaCompleto);
      expect(v.salarioMin, 8000.0);
      expect(v.salarioMax, 15000.0);
    });

    test('preenche habilidades (hard skills) como lista', () {
      final v = Vaga.fromMap(mapaCompleto);
      expect(v.habilidades, isNotNull);
      expect(v.habilidades, containsAll(['Flutter', 'Dart', 'Firebase']));
    });

    test('preenche softSkills como lista', () {
      final v = Vaga.fromMap(mapaCompleto);
      expect(v.softSkills, isNotNull);
      expect(v.softSkills, contains('Comunicação'));
    });

    test('retorna null para campos V1 ausentes no mapa', () {
      final mapaBasico = <String, dynamic>{
        'titulo': 'Vaga Simples',
        'descricao': 'Descrição',
        'criado_em': criadoEm,
        'atualizado_em': atualizadoEm,
      };
      final v = Vaga.fromMap(mapaBasico);

      expect(v.senioridade, isNull);
      expect(v.modalidade, isNull);
      expect(v.salarioMin, isNull);
      expect(v.salarioMax, isNull);
      expect(v.habilidades, isNull);
      expect(v.softSkills, isNull);
    });
  });

  // ── toMap inclui novos campos ──────────────────────────────────────────────

  group('Vaga.toMap — campos V1', () {
    test('serializa senioridade quando não nula', () {
      const v = Vaga(
        titulo: 'Dev',
        descricao: 'Desc',
        criadoEm: criadoEm,
        atualizadoEm: atualizadoEm,
        senioridade: 'pleno',
      );
      final m = v.toMap();
      expect(m['senioridade'], 'pleno');
    });

    test('serializa habilidades quando não nulas', () {
      const v = Vaga(
        titulo: 'Dev',
        descricao: 'Desc',
        criadoEm: criadoEm,
        atualizadoEm: atualizadoEm,
        habilidades: ['Flutter', 'Dart'],
      );
      final m = v.toMap();
      expect(m['habilidades'], ['Flutter', 'Dart']);
    });

    test('serializa softSkills quando não nulas', () {
      const v = Vaga(
        titulo: 'Dev',
        descricao: 'Desc',
        criadoEm: criadoEm,
        atualizadoEm: atualizadoEm,
        softSkills: ['Liderança', 'Comunicação'],
      );
      final m = v.toMap();
      expect(m['soft_skills'], ['Liderança', 'Comunicação']);
    });

    test('omite campos V1 nulos do mapa', () {
      const v = Vaga(
        titulo: 'Dev',
        descricao: 'Desc',
        criadoEm: criadoEm,
        atualizadoEm: atualizadoEm,
      );
      final m = v.toMap();
      expect(m.containsKey('senioridade'), isFalse);
      expect(m.containsKey('modalidade'), isFalse);
      expect(m.containsKey('salario_min'), isFalse);
      expect(m.containsKey('salario_max'), isFalse);
      expect(m.containsKey('habilidades'), isFalse);
      expect(m.containsKey('soft_skills'), isFalse);
    });
  });

  // ── copyWith com novos campos ──────────────────────────────────────────────

  group('Vaga.copyWith — campos V1', () {
    const original = Vaga(
      titulo: 'Dev Junior',
      descricao: 'Vaga junior',
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm,
      senioridade: 'junior',
      modalidade: 'presencial',
      salarioMin: 3000.0,
      salarioMax: 5000.0,
      habilidades: ['Flutter'],
      softSkills: ['Proatividade'],
    );

    test('altera senioridade mantendo demais campos', () {
      final v = original.copyWith(senioridade: 'senior');
      expect(v.senioridade, 'senior');
      expect(v.titulo, original.titulo);
      expect(v.modalidade, original.modalidade);
    });

    test('altera habilidades mantendo softSkills', () {
      final v = original.copyWith(
          habilidades: ['Flutter', 'Dart', 'Firebase']);
      expect(v.habilidades, containsAll(['Flutter', 'Dart', 'Firebase']));
      expect(v.softSkills, original.softSkills);
    });

    test('altera salarioMax mantendo salarioMin', () {
      final v = original.copyWith(salarioMax: 12000.0);
      expect(v.salarioMax, 12000.0);
      expect(v.salarioMin, original.salarioMin);
    });

    test('sem argumentos retorna cópia com campos idênticos', () {
      final v = original.copyWith();
      expect(v.titulo, original.titulo);
      expect(v.senioridade, original.senioridade);
      expect(v.habilidades, original.habilidades);
      expect(v.softSkills, original.softSkills);
    });
  });
}
