import 'package:flutter_test/flutter_test.dart';
import 'package:rh_os/data/parsers/extrator_dados.dart';

void main() {
  final extrator = ExtratorDados();

  // ──────────────────────────────────────────────────────────────────
  // Currículo 1 — Engenheiro de Software
  // ──────────────────────────────────────────────────────────────────
  group('Currículo 1 — Engenheiro de Software', () {
    late Map<String, dynamic> dados;

    setUpAll(() {
      const texto = '''
João Silva
joao.silva@email.com
+55 (11) 98765-4321
CPF: 123.456.789-09

Resumo
Engenheiro de Software com 3 anos de experiência em desenvolvimento mobile.

Experiência
Desenvolvedor Flutter - TechCorp - 01/2022 - 01/2024 - Remoto
Desenvolveu aplicativos mobile para iOS e Android.

Formação
Universidade de São Paulo - Ciência da Computação - Graduação - 2021

Habilidades
Flutter, Dart, Firebase, Git, Clean Architecture

Idiomas
Inglês - Avançado
''';
      dados = extrator.extrair(texto);
    });

    test('email é extraído corretamente', () {
      expect(dados['email'], 'joao.silva@email.com');
    });

    test('telefone é extraído corretamente', () {
      expect(dados['telefone'], isNotNull);
      expect(dados['telefone'].toString(), contains('98765-4321'));
    });

    test('CPF é extraído corretamente', () {
      expect(dados['cpf'], isNotNull);
      expect(dados['cpf'].toString(), contains('123'));
    });

    test('habilidades contêm Flutter', () {
      final habilidades = dados['habilidades'] as List;
      expect(habilidades.any((h) => h.toString().contains('Flutter')), isTrue);
    });

    test('idiomas contêm Inglês', () {
      final idiomas = dados['idiomas'] as List;
      expect(idiomas.any((i) => i['nome'].toString().contains('Inglês')), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Currículo 2 — Designer UX
  // ──────────────────────────────────────────────────────────────────
  group('Currículo 2 — Designer UX', () {
    late Map<String, dynamic> dados;

    setUpAll(() {
      const texto = '''
Maria Santos
maria.santos@design.com
(21) 3456-7890

Resumo
Designer UX/UI com foco em mobile e experiências digitais.

Habilidades
Figma, Adobe XD, Sketch, Prototipagem, Design System

Idiomas
Inglês - Intermediário
Espanhol - Básico

Formação
PUC-Rio - Design Digital - Graduação - 2020
''';
      dados = extrator.extrair(texto);
    });

    test('email é extraído corretamente', () {
      expect(dados['email'], 'maria.santos@design.com');
    });

    test('telefone é extraído corretamente', () {
      expect(dados['telefone'], isNotNull);
      expect(dados['telefone'].toString(), contains('3456'));
    });

    test('CPF é null (ausente no currículo)', () {
      expect(dados['cpf'], isNull);
    });

    test('habilidades contêm Figma', () {
      final habilidades = dados['habilidades'] as List;
      expect(habilidades.any((h) => h.toString().contains('Figma')), isTrue);
    });

    test('dois idiomas encontrados', () {
      final idiomas = dados['idiomas'] as List;
      expect(idiomas.length, 2);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Currículo 3 — Analista Financeiro (sem CPF, sem telefone)
  // ──────────────────────────────────────────────────────────────────
  group('Currículo 3 — Analista Financeiro (campos ausentes)', () {
    late Map<String, dynamic> dados;

    setUpAll(() {
      const texto = '''
Carlos Oliveira
carlos.oliveira@financas.com

Experiência
Analista Financeiro Sênior - Banco Nacional - 03/2019 - atual - Presencial
Gestão de carteiras de investimento e análise de risco.

Formação
FGV - Administração - Pós-graduação - 2018

Habilidades
Excel, Power BI, SQL, Análise de Risco
''';
      dados = extrator.extrair(texto);
    });

    test('email é extraído corretamente', () {
      expect(dados['email'], 'carlos.oliveira@financas.com');
    });

    test('telefone é null (ausente no currículo)', () {
      expect(dados['telefone'], isNull);
    });

    test('CPF é null (ausente no currículo)', () {
      expect(dados['cpf'], isNull);
    });

    test('campos ausentes retornam null sem lançar exceção', () {
      expect(() => dados['cpf'], returnsNormally);
      expect(() => dados['telefone'], returnsNormally);
      expect(() => dados['dataNascimento'], returnsNormally);
      expect(() => dados['cep'], returnsNormally);
    });
  });
}
