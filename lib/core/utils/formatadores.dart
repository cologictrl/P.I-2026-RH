// Utilitarios de formatacao para exibicao.

abstract class Formatadores {
  // Retorna iniciais (primeiro e ultimo nome).
  static String iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return '${partes[0][0]}${partes[partes.length - 1][0]}'.toUpperCase();
  }

  // Formata CPF no padrao 000.000.000-00.
  static String cpf(String cpf) {
    final limpo = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (limpo.length != 11) return cpf;
    return '${limpo.substring(0, 3)}.${limpo.substring(3, 6)}.${limpo.substring(6, 9)}-${limpo.substring(9)}';
  }

  // Formata telefone com DDD (aceita +55).
  static String telefone(String tel) {
    final limpo = tel.replaceAll(RegExp(r'[^\d+]'), '');
    if (limpo.startsWith('+55') && limpo.length == 14) {
      final ddd = limpo.substring(3, 5);
      final num = limpo.substring(5);
      return '+55 ($ddd) ${num.substring(0, 5)}-${num.substring(5)}';
    }
    if (limpo.length == 11) {
      return '(${limpo.substring(0, 2)}) ${limpo.substring(2, 7)}-${limpo.substring(7)}';
    }
    return tel;
  }

  // Formata CEP no padrao 00000-000.
  static String cep(String cep) {
    final limpo = cep.replaceAll(RegExp(r'[^\d]'), '');
    if (limpo.length != 8) return cep;
    return '${limpo.substring(0, 5)}-${limpo.substring(5)}';
  }

  // Calcula idade a partir de data (dd/MM/yyyy ou yyyy-MM-dd).
  static int calcularIdade(String? dataNascimento) {
    if (dataNascimento == null || dataNascimento.isEmpty) return 0;
    try {
      DateTime nascimento;
      if (dataNascimento.contains('/')) {
        final partes = dataNascimento.split('/');
        if (partes.length == 3) {
          nascimento = DateTime(
            int.parse(partes[2]),
            int.parse(partes[1]),
            int.parse(partes[0]),
          );
        } else {
          return 0;
        }
      } else if (dataNascimento.contains('-')) {
        nascimento = DateTime.parse(dataNascimento);
      } else {
        return 0;
      }
      final hoje = DateTime.now();
      int idade = hoje.year - nascimento.year;
      if (hoje.month < nascimento.month ||
          (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
        idade--;
      }
      return idade;
    } catch (_) {
      return 0;
    }
  }

  // Converte data ISO para dd/MM/yyyy quando possivel.
  static String dataBr(String? data) {
    if (data == null || data.isEmpty) return '';
    if (data.contains('/')) return data;
    if (data.contains('-') && data.length == 10) {
      final partes = data.split('-');
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    }
    return data;
  }

  // Retorna nome abreviado com limite de tamanho.
  static String nomeCurto(String nome, {int maxLength = 20}) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return nome;
    if (partes.length == 1) return partes[0];
    final resultado = '${partes[0]} ${partes[partes.length - 1]}';
    if (resultado.length > maxLength) {
      return '${partes[0]} ${partes[partes.length - 1][0]}.';
    }
    return resultado;
  }
}
