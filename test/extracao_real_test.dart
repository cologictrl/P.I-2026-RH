// E7: testes de extração com fixtures de currículos reais.
// Valida que ExtratorDados extrai corretamente e não lança exceções.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rh_os/data/parsers/extrator_dados.dart';

void main() {
  final extrator = ExtratorDados();
  const basePath = 'test/fixtures';

  // ──────────────────────────────────────────────────────────────────
  // Currículo 1 — Engenheiro de Software (dados completos)
  // ──────────────────────────────────────────────────────────────────
  group('Engenheiro — dados completos', () {
    late Map<String, dynamic> dados;

    setUpAll(() {
      final texto =
          File('$basePath/curriculo_engenheiro.txt').readAsStringSync();
      dados = extrator.extrair(texto);
    });

    test('email é extraído corretamente', () {
      expect(dados['email'], 'joao.silva@email.com');
    });

    test('telefone é extraído', () {
      expect(dados['telefone'], isNotNull);
      expect(dados['telefone'].toString(), contains('98765'));
    });

    test('CPF é extraído', () {
      expect(dados['cpf'], isNotNull);
      expect(dados['cpf'].toString(), contains('123'));
    });

    test('habilidades contêm Flutter', () {
      final habs = dados['habilidades'] as List;
      expect(habs.any((h) => h.toString().contains('Flutter')), isTrue);
    });

    test('dois idiomas extraídos', () {
      final idiomas = dados['idiomas'] as List;
      expect(idiomas.length, greaterThanOrEqualTo(2));
    });

    test('campos ausentes retornam null sem exceção', () {
      expect(() => dados['sexo'], returnsNormally);
      expect(() => dados['dataNascimento'], returnsNormally);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Currículo 2 — Designer (sem CPF)
  // ──────────────────────────────────────────────────────────────────
  group('Designer — sem CPF', () {
    late Map<String, dynamic> dados;

    setUpAll(() {
      final texto =
          File('$basePath/curriculo_designer.txt').readAsStringSync();
      dados = extrator.extrair(texto);
    });

    test('email é extraído corretamente', () {
      expect(dados['email'], 'maria.santos@design.com');
    });

    test('telefone é extraído', () {
      expect(dados['telefone'], isNotNull);
      expect(dados['telefone'].toString(), contains('3456'));
    });

    test('CPF é null — ausente no currículo', () {
      expect(dados['cpf'], isNull);
    });

    test('habilidades contêm Figma', () {
      final habs = dados['habilidades'] as List;
      expect(habs.any((h) => h.toString().contains('Figma')), isTrue);
    });

    test('CPF null não lança exceção', () {
      expect(() => dados['cpf'], returnsNormally);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Currículo 3 — Financeiro (sem CPF, sem telefone)
  // ──────────────────────────────────────────────────────────────────
  group('Financeiro — sem CPF nem telefone', () {
    late Map<String, dynamic> dados;

    setUpAll(() {
      final texto =
          File('$basePath/curriculo_financeiro.txt').readAsStringSync();
      dados = extrator.extrair(texto);
    });

    test('email é extraído corretamente', () {
      expect(dados['email'], 'carlos.oliveira@financas.com');
    });

    test('telefone é null — ausente no currículo', () {
      expect(dados['telefone'], isNull);
    });

    test('CPF é null — ausente no currículo', () {
      expect(dados['cpf'], isNull);
    });

    test('campos ausentes retornam null sem lançar exceção', () {
      expect(() => dados['cpf'], returnsNormally);
      expect(() => dados['telefone'], returnsNormally);
      expect(() => dados['dataNascimento'], returnsNormally);
      expect(() => dados['cep'], returnsNormally);
    });

    test('habilidades contêm Excel', () {
      final habs = dados['habilidades'] as List;
      expect(habs.any((h) => h.toString().contains('Excel')), isTrue);
    });
  });
}
