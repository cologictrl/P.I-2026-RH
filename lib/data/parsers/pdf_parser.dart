// Parser de PDF para extracao de texto.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfParser {
  // Extrai texto de um arquivo PDF salvo em disco.
  Future<String> extrairTexto(String caminho) async {
    PdfDocument? documento;
    try {
      final arquivo = File(caminho);
      if (!arquivo.existsSync()) return '';

      final bytes = await arquivo.readAsBytes();
      documento = PdfDocument(inputBytes: bytes);

      final extrator = PdfTextExtractor(documento);
      final buffer = StringBuffer();

      for (var i = 0; i < documento.pages.count; i++) {
        final pagina = extrator.extractText(startPageIndex: i, endPageIndex: i);
        if (pagina.isNotEmpty) {
          buffer.writeln(pagina);
        }
      }

      final texto = buffer.toString().trim();

      if (texto.length < 50) {
        debugPrint('[PdfParser] PDF escaneado detectado — OCR fase 2');
        return '';
      }

      return texto;
    } catch (e) {
      debugPrint('[PdfParser] Erro ao extrair texto: $e');
      return '';
    } finally {
      documento?.dispose();
    }
  }

  // Extrai texto a partir de bytes (upload).
  Future<String> extrairTextoDosBytes(Uint8List bytes) async {
    try {
      final documento = PdfDocument(inputBytes: bytes);
      final extrator = PdfTextExtractor(documento);
      final texto = extrator.extractText();
      documento.dispose();
      debugPrint('[PdfParser] Bytes extraídos: ${texto.trim().length} chars');
      return texto.trim();
    } catch (e) {
      debugPrint('[PdfParser] Erro ao extrair bytes: $e');
      return '';
    }
  }
}
