// Contrato para OCR/IA.

import 'dart:typed_data';

abstract class OcrService {
  Future<Map<String, dynamic>?> extrairDadosDosBytes(
      Uint8List bytes, String mimeType);
}
