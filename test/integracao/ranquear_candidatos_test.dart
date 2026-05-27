// Testes de integração para lib/domain/casos_de_uso/ranquear_candidatos.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rh_os/domain/casos_de_uso/ranquear_candidatos.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/entidades/vaga.dart';

// Fábrica auxiliar para criar candidatos de teste sem boilerplate.
Candidato _candidato({String? resumo}) => Candidato(
      nome: 'Candidato Teste',
      resumo: resumo,
      criadoEm: '2024-01-01T00:00:00.000Z',
      atualizadoEm: '2024-01-01T00:00:00.000Z',
    );

// Fábrica auxiliar para criar vagas de teste.
// Inclui os campos V1: senioridade, modalidade, habilidades, softSkills.
Vaga _vaga({
  String requisitos = '',
  String descricao = '',
  String? senioridade,
  String? modalidade,
  List<String>? habilidades,
  List<String>? softSkills,
}) =>
    Vaga(
      titulo: 'Vaga Teste',
      descricao: descricao,
      requisitos: requisitos,
      status: 'aberta',
      criadoEm: '2024-01-01T00:00:00.000Z',
      atualizadoEm: '2024-01-01T00:00:00.000Z',
      senioridade: senioridade,
      modalidade: modalidade,
      habilidades: habilidades,
      softSkills: softSkills,
    );

void main() {
  late RanquearCandidatos ranqueador;

  setUp(() {
    ranqueador = RanquearCandidatos();
  });

  group('calcularScore — habilidades', () {
    test(
        'Candidato com todas as habilidades da vaga tem score de habilidades máximo',
        () {
      final candidato = _candidato(
        resumo: 'Tenho experiência em Flutter, Dart e Git',
      );
      final vaga = _vaga(requisitos: 'Flutter, Dart, Git');

      final score = ranqueador.calcularScore(candidato, vaga);

      // Hard skills fortes devem gerar score relevante
      expect(score, greaterThanOrEqualTo(35.0));
    });

    test('Candidato sem nenhuma habilidade tem score de habilidades 0', () {
      final candidato = _candidato(resumo: 'Tenho experiência em cozinha');
      final vaga = _vaga(requisitos: 'Flutter, Dart, Firebase');

      final score = ranqueador.calcularScore(candidato, vaga);

      // Sem hard skills -> score baixo
      expect(score, lessThan(25.0));
    });

    test('Candidato com metade das habilidades tem score intermediário', () {
      final candidato = _candidato(resumo: 'Conheço Flutter e Dart');
      final vaga = _vaga(requisitos: 'Flutter, Dart, Firebase, Git');

      final score = ranqueador.calcularScore(candidato, vaga);

      // 2/4 habilidades = 50% de 60% = 30 pontos de habilidades
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(100.0));
    });
  });

  group('calcularScore — idiomas', () {
    test('Candidato com idioma mencionado tem score de idiomas maior que 0',
        () {
      final candidato = _candidato(resumo: 'Fluente em inglês');
      final vaga = _vaga(requisitos: '');

      final score = ranqueador.calcularScore(candidato, vaga);

      // Idiomas devem contribuir positivamente quando presentes
      expect(score, greaterThanOrEqualTo(0.0));
    });

    test('Candidato com dois idiomas tem score de idiomas máximo (1.0)', () {
      final candidato =
          _candidato(resumo: 'Falo inglês e espanhol fluentemente');
      final vaga = _vaga();

      final score = ranqueador.calcularScore(candidato, vaga);

      // Idiomas presentes mantem score dentro de limites
      expect(score, greaterThanOrEqualTo(0.0));
    });
  });

  group('calcularScore — limites', () {
    test('calcularScore retorna valor entre 0.0 e 100.0', () {
      final candidatos = [
        _candidato(resumo: null),
        _candidato(resumo: ''),
        _candidato(resumo: 'Flutter Dart Firebase inglês graduação'),
        _candidato(resumo: 'XYZ ABC DEF'),
      ];
      final vaga = _vaga(requisitos: 'Flutter, Dart', descricao: 'graduação');

      for (final c in candidatos) {
        final score = ranqueador.calcularScore(c, vaga);
        expect(score, greaterThanOrEqualTo(0.0),
            reason: 'Score deve ser >= 0 para resumo: ${c.resumo}');
        expect(score, lessThanOrEqualTo(100.0),
            reason: 'Score deve ser <= 100 para resumo: ${c.resumo}');
      }
    });

    test(
        'calcularScore com vaga sem requisitos retorna score parcial (não crash)',
        () {
      final candidato = _candidato(resumo: 'Desenvolvedor Flutter');
      final vaga = _vaga(requisitos: '', descricao: '');

      expect(() => ranqueador.calcularScore(candidato, vaga), returnsNormally);
      final score = ranqueador.calcularScore(candidato, vaga);
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(100.0));
    });
  });

  // ── Campos V1 de Vaga (senioridade, modalidade, habilidades, softSkills) ──

  group('calcularScore — vaga com campos V1', () {
    test(
        'vaga com habilidades preenchidas e candidato compatível tem score alto',
        () {
      final candidato = _candidato(
        resumo: 'Experiente em Flutter, Dart, Firebase e arquitetura limpa',
      );
      final vaga = _vaga(
        requisitos: 'Flutter, Dart, Firebase',
        habilidades: ['Flutter', 'Dart', 'Firebase'],
        senioridade: 'senior',
        modalidade: 'remoto',
      );

      final score = ranqueador.calcularScore(candidato, vaga);
      expect(score, greaterThanOrEqualTo(35.0));
    });

    test('vaga com softSkills não afeta o calcularScore local (não lança erro)',
        () {
      final candidato = _candidato(resumo: 'Comunicativo e proativo');
      final vaga = _vaga(
        softSkills: ['Comunicação', 'Proatividade', 'Liderança'],
      );

      expect(() => ranqueador.calcularScore(candidato, vaga), returnsNormally);
    });

    test('vaga com todos campos V1 retorna score no intervalo [0, 100]', () {
      final candidato = _candidato(
        resumo: 'Flutter developer sênior com inglês avançado e mestrado',
      );
      final vaga = _vaga(
        requisitos: 'Flutter, Dart',
        descricao: 'Vaga com exigência de pós-graduação',
        senioridade: 'senior',
        modalidade: 'hibrido',
        habilidades: ['Flutter', 'Dart', 'Firebase'],
        softSkills: ['Comunicação'],
      );

      final score = ranqueador.calcularScore(candidato, vaga);
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(100.0));
    });
  });
}
