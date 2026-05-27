// Extracao de dados de curriculo via Gemini.

import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ocr_service.dart';

class GeminiOcrService implements OcrService {
  // Chave via --dart-define=GEMINI_API_KEY=...
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Prompt fixo exigindo JSON limpo.
  static const _prompt = """
Você é um extrator de dados de currículos profissionais.
Analise o documento e retorne APENAS um JSON válido,
sem texto adicional, sem markdown, sem explicações.

Formato obrigatório:
{
  "nome": null,
  "email": null,
  "telefone": null,
  "cpf": null,
  "dataNascimento": null,
  "sexo": null,
  "logradouro": null,
  "numero": null,
  "bairro": null,
  "cidade": null,
  "estado": null,
  "cep": null,
  "resumo": null,
  "experiencias": [
    {
      "cargo": null,
      "empresa": null,
      "localidade": null,
      "modalidade": null,
      "dataInicio": null,
      "dataFim": null,
      "atual": false,
      "descricao": null
    }
  ],
  "formacoes": [
    {
      "instituicao": null,
      "curso": null,
      "nivel": null,
      "dataInicio": null,
      "dataFim": null,
      "emAndamento": false
    }
  ],
  "habilidades": [],
  "idiomas": [
    {"nome": null, "nivel": null}
  ]
}
Campos não encontrados devem ser null.
Arrays vazios se não houver dados.
Telefone deve conter DDD (10-11 dígitos) e ficar no formato (11) 91234-5678.
CEP deve ter 8 dígitos e ficar no formato 00000-000.
Se houver dúvida entre CEP e telefone, preencha apenas o CEP e deixe telefone null.
""";

  // Parse robusto do JSON retornado pela IA.
  Map<String, dynamic>? _parseJson(String texto) {
    final limpo = texto.replaceAll('```json', '').replaceAll('```', '').trim();
    try {
      return jsonDecode(limpo) as Map<String, dynamic>;
    } catch (_) {}

    final start = limpo.indexOf('{');
    final end = limpo.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    final recorte = limpo.substring(start, end + 1);
    try {
      return jsonDecode(recorte) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> extrairDadosDosBytes(
      Uint8List bytes, String mimeType) async {
    if (_apiKey.isEmpty) {
      debugPrint('[GeminiOCR] API Key não configurada. '
          'Rode com --dart-define=GEMINI_API_KEY=SUA_CHAVE');
      return null;
    }
    try {
      debugPrint('[GeminiOCR] Enviando para Gemini 2.5 Flash...');
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );
      final content = [
        Content.multi([
          DataPart(mimeType, bytes),
          TextPart(_prompt),
        ])
      ];
      final response = await model.generateContent(content);
      final texto = response.text ?? '';
      debugPrint('[GeminiOCR] Resposta: ${texto.length} chars');

      final resultado = _parseJson(texto);
      if (resultado == null) {
        debugPrint('[GeminiOCR] JSON invalido ou ausente');
        return null;
      }
      debugPrint('[GeminiOCR] Campos extraídos: ${resultado.keys.length}');
      return resultado;
    } catch (e, st) {
      debugPrint('[GeminiOCR] Erro: $e');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'GeminiOCR.extrairDadosDosBytes');
      return null;
    }
  }
}
