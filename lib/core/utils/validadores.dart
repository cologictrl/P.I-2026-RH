// Utilitarios de validacao e normalizacao de campos.

abstract class Validadores {
  // Regex principais de validacao.
  static final _regexEmail =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  // Aceita: com/sem +55, com/sem DDD, celular (9 digitos) e fixo (8 digitos).
  static final _regexTelefone = RegExp(
      r'^(\+55[\s\-]?)?(\(?\d{2}\)?[\s\-]?)?\d{4,5}[\s\-]?\d{4}$');

  static final _regexCep = RegExp(r'^\d{5}[\-]?\d{3}$');

  static String? obrigatorio(String? value) {
    // Campo obrigatorio.
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? email(String? value) {
    // E-mail obrigatorio com formato valido RFC basico.
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    if (!_regexEmail.hasMatch(value.trim())) return 'E-mail inválido';
    return null;
  }

  static String? cpf(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final limpo = value.replaceAll(RegExp(r'[.\-\s]'), '');
    if (limpo.length != 11) return 'CPF inválido';
    // Rejeita sequencias repetidas (ex: 000.000.000-00)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(limpo)) return 'CPF inválido';
    // Verifica primeiro digito verificador
    var soma = 0;
    for (var i = 0; i < 9; i++) {
      soma += int.parse(limpo[i]) * (10 - i);
    }
    var resto = (soma * 10) % 11;
    if (resto == 10 || resto == 11) resto = 0;
    if (resto != int.parse(limpo[9])) return 'CPF inválido';
    // Verifica segundo digito verificador
    soma = 0;
    for (var i = 0; i < 10; i++) {
      soma += int.parse(limpo[i]) * (11 - i);
    }
    resto = (soma * 10) % 11;
    if (resto == 10 || resto == 11) resto = 0;
    if (resto != int.parse(limpo[10])) return 'CPF inválido';
    return null;
  }

  static String? telefone(String? value) {
    // Telefone opcional no padrao brasileiro.
    if (value == null || value.trim().isEmpty) return null;
    if (!_regexTelefone.hasMatch(value.trim())) return 'Telefone inválido';
    return null;
  }

  static String? cep(String? value) {
    // CEP opcional: 8 digitos com ou sem hifen.
    if (value == null || value.trim().isEmpty) return null;
    if (!_regexCep.hasMatch(value.trim())) return 'CEP inválido';
    return null;
  }

  static String? normalizarTelefone(String? value) {
    // Normaliza telefone para formato visual.
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      final ddd = digits.substring(0, 2);
      final parte1 = digits.substring(2, 6);
      final parte2 = digits.substring(6);
      return '($ddd) $parte1-$parte2';
    }
    if (digits.length == 11) {
      final ddd = digits.substring(0, 2);
      final parte1 = digits.substring(2, 7);
      final parte2 = digits.substring(7);
      return '($ddd) $parte1-$parte2';
    }
    return null;
  }

  static String? normalizarCep(String? value) {
    // Normaliza CEP para formato 00000-000.
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }

  static String? senha(String? value) {
    // Valida senha minima.
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    if (value.length < 6) return 'Senha deve ter pelo menos 6 caracteres';
    return null;
  }
}
