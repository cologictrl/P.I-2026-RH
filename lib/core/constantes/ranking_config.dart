// Configurações globais do sistema de ranking de candidatos.
abstract class RankingConfig {
  // Pesos do score por rubrica (soma = 1.0)
  static const double pesoHardSkills = 0.40;
  static const double pesoExperiencia = 0.25;
  static const double pesoFormacao = 0.15;
  static const double pesoIdiomas = 0.10;
  static const double pesoSoftSkills = 0.10;

  // Modelo Gemini para ranking
  static const String modeloGemini = 'gemini-2.5-flash';

  // Timeout máximo para chamada de ranking
  static const Duration timeout = Duration(seconds: 30);

  // Máximo de candidatos ranqueados por lote
  static const int maxCandidatosPorLote = 10;
}
