// Testes unitários para RankingService.
// Cobre: vagaParaTexto, candidatoParaTexto, calcularRanking sem API Key,
// e score local via RanquearCandidatos.
// ignore: invalid_use_of_visible_for_testing_member

import 'package:flutter_test/flutter_test.dart';
import 'package:rh_os/data/servicos/ranking_service.dart';
import 'package:rh_os/domain/casos_de_uso/ranquear_candidatos.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/entidades/habilidade.dart';
import 'package:rh_os/domain/entidades/idioma.dart';
import 'package:rh_os/domain/entidades/vaga.dart';

// ── Fábricas auxiliares ────────────────────────────────────────────────────

Vaga _vaga({
  String titulo = 'Dev Flutter',
  String descricao = 'Vaga de desenvolvimento',
  String? senioridade,
  String? modalidade,
  List<String>? habilidades,
  List<String>? softSkills,
}) =>
    Vaga(
      titulo: titulo,
      descricao: descricao,
      requisitos: habilidades?.join(', ') ?? 'Flutter, Dart',
      status: 'aberta',
      criadoEm: '2024-01-01T00:00:00.000Z',
      atualizadoEm: '2024-01-01T00:00:00.000Z',
      senioridade: senioridade,
      modalidade: modalidade,
      habilidades: habilidades,
      softSkills: softSkills,
    );

Candidato _candidato({
  String nome = 'João Teste',
  String? resumo,
}) =>
    Candidato(
      nome: nome,
      resumo: resumo,
      criadoEm: '2024-01-01T00:00:00.000Z',
      atualizadoEm: '2024-01-01T00:00:00.000Z',
    );

void main() {
  late RankingService service;
  late RanquearCandidatos ranqueador;

  setUp(() {
    service = RankingService();
    ranqueador = RanquearCandidatos();
  });

  // ── vagaParaTexto ──────────────────────────────────────────────────────────

  group('vagaParaTexto', () {
    test('retorna string contendo o título da vaga', () {
      // ignore: invalid_use_of_visible_for_testing_member
      final texto = service.vagaParaTexto(_vaga(titulo: 'Engenheiro Sênior'));

      expect(texto, contains('Engenheiro Sênior'));
    });

    test('retorna string contendo hard skills quando informadas', () {
      final vaga = _vaga(habilidades: ['Flutter', 'Dart', 'Firebase']);
      // ignore: invalid_use_of_visible_for_testing_member
      final texto = service.vagaParaTexto(vaga);

      expect(texto, contains('Flutter'));
      expect(texto, contains('Firebase'));
    });

    test('retorna string com senioridade e modalidade quando informadas', () {
      final vaga = _vaga(senioridade: 'senior', modalidade: 'remoto');
      // ignore: invalid_use_of_visible_for_testing_member
      final texto = service.vagaParaTexto(vaga);

      expect(texto, contains('senior'));
      expect(texto, contains('remoto'));
    });
  });

  // ── candidatoParaTexto ────────────────────────────────────────────────────

  group('candidatoParaTexto', () {
    test('retorna string contendo o nome do candidato', () {
      final candidato = _candidato(nome: 'Maria da Silva');
      // ignore: invalid_use_of_visible_for_testing_member
      final texto = service.candidatoParaTexto(candidato);

      expect(texto, contains('Maria da Silva'));
    });

    test('retorna string contendo habilidades passadas', () {
      final candidato = _candidato(nome: 'Carlos');
      final habilidades = [
        const Habilidade(candidatoId: 0, nome: 'Flutter', nivel: 'Avançado'),
        const Habilidade(candidatoId: 0, nome: 'Dart', nivel: 'Avançado'),
      ];
      // ignore: invalid_use_of_visible_for_testing_member
      final texto = service.candidatoParaTexto(
        candidato,
        habilidades: habilidades,
      );

      expect(texto, contains('Flutter'));
      expect(texto, contains('Dart'));
    });

    test('retorna string contendo idiomas passados', () {
      final candidato = _candidato(nome: 'Ana');
      final idiomas = [
        const Idioma(candidatoId: 0, nome: 'Inglês', nivel: 'Avançado'),
      ];
      // ignore: invalid_use_of_visible_for_testing_member
      final texto = service.candidatoParaTexto(
        candidato,
        idiomas: idiomas,
      );

      expect(texto, contains('Inglês'));
      expect(texto, contains('Avançado'));
    });
  });

  // ── calcularRanking sem API Key ──────────────────────────────────────────

  group('calcularRanking — sem API Key', () {
    test('retorna null quando API Key está vazia (sem lançar erro)', () async {
      // Em ambiente de teste, GEMINI_API_KEY não é definida via --dart-define,
      // portanto String.fromEnvironment retorna '' → deve retornar null.
      final resultado = await service.calcularRanking(
        _vaga(),
        _candidato(),
      );

      expect(resultado, isNull);
    });
  });

  // ── calcularScore local (RanquearCandidatos) ──────────────────────────────

  group('calcularScore local', () {
    test('candidato com todas as habilidades da vaga tem score alto', () {
      final candidato = _candidato(
        resumo: 'Tenho experiência em Flutter, Dart e Firebase',
      );
      final vaga = _vaga(
        habilidades: ['Flutter', 'Dart', 'Firebase'],
      );

      final score = ranqueador.calcularScore(candidato, vaga);

      // Hard skills fortes + indicio de experiencia -> score deve ser relevante
      expect(score, greaterThanOrEqualTo(35.0));
    });

    test('candidato sem nenhuma habilidade tem score baixo', () {
      final candidato = _candidato(
        resumo: 'Sou chef de cozinha especializado em gastronomia italiana',
      );
      final vaga = _vaga(
        habilidades: ['Flutter', 'Dart', 'Firebase', 'Kotlin', 'iOS'],
      );

      final score = ranqueador.calcularScore(candidato, vaga);

      // Sem hard skills -> score baixo
      expect(score, lessThan(25.0));
    });

    test('score está sempre entre 0 e 100', () {
      final candidatos = [
        _candidato(resumo: null),
        _candidato(resumo: ''),
        _candidato(resumo: 'Flutter Dart inglês graduação Firebase'),
        _candidato(resumo: 'XYZ ABC DEF'),
      ];
      final vaga = _vaga(habilidades: ['Flutter', 'Dart']);

      for (final c in candidatos) {
        final score = ranqueador.calcularScore(c, vaga);
        expect(score, greaterThanOrEqualTo(0.0),
            reason: 'Score deve ser >= 0 para resumo: ${c.resumo}');
        expect(score, lessThanOrEqualTo(100.0),
            reason: 'Score deve ser <= 100 para resumo: ${c.resumo}');
      }
    });
  });
}
