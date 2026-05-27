// Testes de integração para lib/core/utils/validadores.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rh_os/core/utils/validadores.dart';

void main() {
  group('Validadores.cpf', () {
    test('CPF válido retorna null (sem erro)', () {
      // 529.982.247-25 — CPF válido real
      expect(Validadores.cpf('529.982.247-25'), isNull);
    });

    test('CPF inválido retorna mensagem de erro', () {
      expect(Validadores.cpf('123.456.789-00'), equals('CPF inválido'));
    });

    test('CPF com sequência repetida (111.111.111-11) é inválido', () {
      expect(Validadores.cpf('111.111.111-11'), equals('CPF inválido'));
    });

    test('CPF com sequência repetida (000.000.000-00) é inválido', () {
      expect(Validadores.cpf('000.000.000-00'), equals('CPF inválido'));
    });

    test('CPF vazio retorna null (campo opcional)', () {
      expect(Validadores.cpf(''), isNull);
      expect(Validadores.cpf(null), isNull);
    });

    test('CPF com dígitos insuficientes é inválido', () {
      expect(Validadores.cpf('123.456.789'), equals('CPF inválido'));
    });
  });

  group('Validadores.email', () {
    test('Email válido retorna null', () {
      expect(Validadores.email('usuario@dominio.com'), isNull);
    });

    test('Email com subdomínio válido retorna null', () {
      expect(Validadores.email('usuario@mail.dominio.com.br'), isNull);
    });

    test('Email inválido retorna mensagem de erro', () {
      expect(Validadores.email('não-é-email'), equals('E-mail inválido'));
    });

    test('Email sem @ retorna erro', () {
      expect(Validadores.email('semArroba.com'), equals('E-mail inválido'));
    });

    test('Email vazio retorna erro (campo obrigatório)', () {
      expect(Validadores.email(''), equals('Campo obrigatório'));
      expect(Validadores.email(null), equals('Campo obrigatório'));
    });
  });

  group('Validadores.telefone', () {
    test('Telefone com DDD (11 dígitos) retorna null', () {
      expect(Validadores.telefone('(11) 91234-5678'), isNull);
    });

    test('Telefone fixo com DDD (10 dígitos) retorna null', () {
      expect(Validadores.telefone('(11) 3456-7890'), isNull);
    });

    test('Telefone sem DDD (8 dígitos) retorna null', () {
      expect(Validadores.telefone('3456-7890'), isNull);
    });

    test('Telefone sem DDD (9 dígitos) retorna null', () {
      expect(Validadores.telefone('91234-5678'), isNull);
    });

    test('Telefone vazio retorna null (campo opcional)', () {
      expect(Validadores.telefone(''), isNull);
      expect(Validadores.telefone(null), isNull);
    });
  });

  group('Validadores.cep', () {
    test('CEP válido com hífen retorna null', () {
      expect(Validadores.cep('01310-100'), isNull);
    });

    test('CEP válido sem hífen retorna null', () {
      expect(Validadores.cep('01310100'), isNull);
    });

    test('CEP inválido (menos de 8 dígitos) retorna erro', () {
      expect(Validadores.cep('0131'), equals('CEP inválido'));
    });

    test('CEP inválido (letras) retorna erro', () {
      expect(Validadores.cep('ABCDE-FGH'), equals('CEP inválido'));
    });

    test('CEP vazio retorna null (campo opcional)', () {
      expect(Validadores.cep(''), isNull);
      expect(Validadores.cep(null), isNull);
    });
  });
}
