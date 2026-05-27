// Parser de TXT com fallback de encoding.
import 'dart:io';
import 'dart:convert';

class TxtParser {
  // Tenta UTF-8 e faz fallback para Latin-1.
  Future<String> extrairTexto(String caminho) async {
    try {
      final arquivo = File(caminho);
      if (!arquivo.existsSync()) return '';

      try {
        return await arquivo.readAsString(encoding: utf8);
      } catch (_) {}

      try {
        return await arquivo.readAsString(encoding: latin1);
      } catch (_) {}

      return '';
    } catch (_) {
      return '';
    }
  }
}
