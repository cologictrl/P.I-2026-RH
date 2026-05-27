// Serviço de ranking de candidatos usando Gemini 2.5 Flash.
// Recebe vaga e candidato (com listas opcionais) e retorna score + justificativa.
import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'; // inclui @visibleForTesting
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:rh_os/core/constantes/ranking_config.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/entidades/experiencia.dart';
import 'package:rh_os/domain/entidades/formacao.dart';
import 'package:rh_os/domain/entidades/habilidade.dart';
import 'package:rh_os/domain/entidades/idioma.dart';
import 'package:rh_os/domain/entidades/vaga.dart';

class RankingService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const _prompt = '''
Você é um avaliador de candidatos para vagas de emprego.
Analise a compatibilidade entre a vaga e o candidato abaixo
e retorne APENAS um JSON válido, sem texto adicional:
{
  "score_total": 0,
  "scores_por_eixo": {
    "hard_skills": 0,
    "soft_skills": 0,
    "experiencia": 0,
    "formacao": 0,
    "idiomas": 0
  },
  "gating_aprovado": true,
  "requisitos_nao_atendidos": [],
  "justificativa": "",
  "pontos_fortes": [],
  "pontos_fracos": []
}

Regras:
- Cada eixo deve ter nota 0..5.
- 0 = sem utilidade para a vaga.
- 1..3 = pouca utilidade.
- 4 = util para a vaga.
- 5 = requisito explicitamente pedido na vaga.
- score_total deve ser 0..100 baseado nos eixos.
- Se faltar requisito obrigatorio, marque gating_aprovado=false e liste em requisitos_nao_atendidos.

Pontos fortes e fracos são listas de strings curtas.

VAGA:
{vaga}

CANDIDATO:
{candidato}
''';

  /// Calcula ranking via Gemini. Retorna null se API Key ausente ou erro.
  /// As listas [habilidades], [idiomas] e [experiencias] enriquecem o contexto
  /// enviado ao modelo; passá-las é opcional mas melhora a qualidade do score.
  Future<Map<String, dynamic>?> calcularRanking(
    Vaga vaga,
    Candidato candidato, {
    List<Habilidade> habilidades = const [],
    List<Idioma> idiomas = const [],
    List<Experiencia> experiencias = const [],
    List<Formacao> formacoes = const [],
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint(
          '[RankingService] API Key não configurada — usando score local');
      return null;
    }
    try {
      final model = GenerativeModel(
        model: RankingConfig.modeloGemini,
        apiKey: _apiKey,
      );

      final prompt =
          _prompt.replaceAll('{vaga}', vagaParaTexto(vaga)).replaceAll(
                '{candidato}',
                candidatoParaTexto(
                  candidato,
                  habilidades: habilidades,
                  idiomas: idiomas,
                  experiencias: experiencias,
                  formacoes: formacoes,
                ),
              );

      final response = await model.generateContent(
          [Content.text(prompt)]).timeout(RankingConfig.timeout);

      final texto = response.text ?? '';
      final json = texto.replaceAll('```json', '').replaceAll('```', '').trim();

      final bruto = jsonDecode(json) as Map<String, dynamic>;
      final resultado = _normalizarResultado(bruto);
      debugPrint(
          '[RankingService] Score: ${resultado['score_total']} para ${candidato.nome}');
      return resultado;
    } catch (e, st) {
      debugPrint('[RankingService] Erro: $e');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'RankingService.calcularRanking');
      return null;
    }
  }

  /// Formata a vaga em texto para o prompt do Gemini.
  /// Exposto para testes via @visibleForTesting.
  @visibleForTesting
  String vagaParaTexto(Vaga vaga) => 'Título: ${vaga.titulo}\n'
      'Descrição: ${vaga.descricao}\n'
      'Requisitos: ${vaga.requisitos ?? ""}\n'
      'Hard Skills: ${vaga.habilidades?.join(", ") ?? ""}\n'
      'Soft Skills: ${vaga.softSkills?.join(", ") ?? ""}\n'
      'Senioridade: ${vaga.senioridade ?? ""}\n'
      'Local: ${vaga.local ?? ""}\n'
      'Modalidade: ${vaga.modalidade ?? ""}';

  /// Formata o candidato em texto para o prompt do Gemini.
  /// Exposto para testes via @visibleForTesting.
  @visibleForTesting
  String candidatoParaTexto(
    Candidato candidato, {
    List<Habilidade> habilidades = const [],
    List<Idioma> idiomas = const [],
    List<Experiencia> experiencias = const [],
    List<Formacao> formacoes = const [],
  }) =>
      'Nome: ${candidato.nome}\n'
      'Resumo: ${candidato.resumo ?? ""}\n'
      'Habilidades: ${habilidades.map((h) => h.nome).join(", ")}\n'
      'Idiomas: ${idiomas.map((i) => "${i.nome} (${i.nivel})").join(", ")}\n'
      'Experiências: ${experiencias.map((e) => "${e.cargo} em ${e.empresa}").join("; ")}\n'
      'Formação: ${formacoes.map((f) => "${f.curso} (${f.nivel})").join("; ")}';

  Map<String, dynamic> _normalizarResultado(Map<String, dynamic> bruto) {
    final scores =
        (bruto['scores_por_eixo'] as Map?)?.cast<String, dynamic>() ??
            (bruto['scores'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    double scoreTotal;
    if (bruto['score_total'] is num) {
      scoreTotal = (bruto['score_total'] as num).toDouble();
    } else if (bruto['score'] is num) {
      scoreTotal = (bruto['score'] as num).toDouble();
    } else {
      scoreTotal = _calcularScoreTotal(scores);
    }

    return {
      ...bruto,
      'scores_por_eixo': scores,
      'score_total': scoreTotal,
      'score': scoreTotal,
      'gating_aprovado': bruto['gating_aprovado'] ?? true,
      'requisitos_nao_atendidos':
          bruto['requisitos_nao_atendidos'] as List? ?? <String>[],
    };
  }

  double _calcularScoreTotal(Map<String, dynamic> scores) {
    double eixo(String chave) {
      final v = scores[chave];
      if (v is num) return v.toDouble().clamp(0.0, 5.0);
      return 0.0;
    }

    final hard = eixo('hard_skills');
    final soft = eixo('soft_skills');
    final exp = eixo('experiencia');
    final form = eixo('formacao');
    final idi = eixo('idiomas');

    final total = (hard / 5.0) * RankingConfig.pesoHardSkills +
        (exp / 5.0) * RankingConfig.pesoExperiencia +
        (form / 5.0) * RankingConfig.pesoFormacao +
        (idi / 5.0) * RankingConfig.pesoIdiomas +
        (soft / 5.0) * RankingConfig.pesoSoftSkills;

    return double.parse((total * 100).toStringAsFixed(1));
  }
}
