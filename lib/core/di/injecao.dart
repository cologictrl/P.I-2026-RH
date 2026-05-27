// Registro central de dependencias via get_it.
import 'package:get_it/get_it.dart';
import 'package:rh_os/data/parsers/ocr/gemini_ocr_service.dart';
import 'package:rh_os/data/repositorios/candidato_repositorio_firestore.dart';
import 'package:rh_os/data/repositorios/candidatura_repositorio_firestore.dart';
import 'package:rh_os/data/repositorios/entrevista_repositorio_firestore.dart';
import 'package:rh_os/data/repositorios/notificacao_repositorio_firestore.dart';
import 'package:rh_os/data/repositorios/ranking_repositorio_firestore.dart';
import 'package:rh_os/data/repositorios/usuario_repositorio_firestore.dart';
import 'package:rh_os/data/repositorios/vaga_repositorio_firestore.dart';
import 'package:rh_os/data/servicos/auditoria_service.dart';
import 'package:rh_os/data/servicos/firebase_auth_service.dart';
import 'package:rh_os/data/servicos/ranking_service.dart';
import 'package:rh_os/domain/casos_de_uso/autenticar_usuario.dart';
import 'package:rh_os/domain/casos_de_uso/candidaturas/listar_candidaturas_por_vaga.dart';
import 'package:rh_os/domain/casos_de_uso/candidatos/deletar_candidato.dart';
import 'package:rh_os/domain/casos_de_uso/candidatos/listar_candidatos.dart';
import 'package:rh_os/domain/casos_de_uso/candidatos/merge_candidato.dart';
import 'package:rh_os/domain/casos_de_uso/candidatos/salvar_candidato.dart';
import 'package:rh_os/domain/casos_de_uso/candidatos/verificar_duplicidade.dart';
import 'package:rh_os/domain/casos_de_uso/extrair_dados_curriculo.dart';
import 'package:rh_os/domain/casos_de_uso/ranquear_candidatos.dart';
import 'package:rh_os/domain/casos_de_uso/upload_curriculo.dart';
import 'package:rh_os/domain/casos_de_uso/vagas/listar_vagas.dart';
import 'package:rh_os/domain/casos_de_uso/vagas/salvar_vaga.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';
import 'package:rh_os/domain/repositorios/i_candidatura_repositorio.dart';
import 'package:rh_os/domain/repositorios/i_notificacao_repositorio.dart';
import 'package:rh_os/domain/repositorios/i_usuario_repositorio.dart';
import 'package:rh_os/domain/repositorios/i_vaga_repositorio.dart';

final GetIt getIt = GetIt.instance;

Future<void> configurarDependencias() async {
  // Servicos e integrações externas
  getIt.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  getIt.registerLazySingleton<GeminiOcrService>(() => GeminiOcrService());
  getIt.registerLazySingleton<AuditoriaService>(() => AuditoriaService());

  // Repositorios de dados
  getIt.registerLazySingleton<IUsuarioRepositorio>(
    () => UsuarioRepositorioFirestore(),
  );
  getIt.registerLazySingleton<ICandidatoRepositorio>(
    () => CandidatoRepositorioFirestore(),
  );
  getIt.registerLazySingleton<IVagaRepositorio>(
    () => VagaRepositorioFirestore(),
  );
  getIt.registerLazySingleton<ICandidaturaRepositorio>(
    () => CandidaturaRepositorioFirestore(),
  );
  getIt.registerLazySingleton<INotificacaoRepositorio>(
    () => NotificacaoRepositorioFirestore(),
  );

  // Casos de uso
  getIt.registerLazySingleton<AutenticarUsuario>(
    () => AutenticarUsuario(
      getIt<FirebaseAuthService>(),
      getIt<IUsuarioRepositorio>(),
    ),
  );
  getIt.registerLazySingleton<UploadCurriculo>(() => UploadCurriculo());
  getIt.registerLazySingleton<ExtrairDadosCurriculo>(
    () => ExtrairDadosCurriculo(),
  );
  getIt.registerLazySingleton<ListarCandidatos>(
    () => ListarCandidatos(getIt<ICandidatoRepositorio>()),
  );
  getIt.registerLazySingleton<SalvarCandidato>(
    () => SalvarCandidato(getIt<ICandidatoRepositorio>()),
  );
  getIt.registerLazySingleton<DeletarCandidato>(
    () => DeletarCandidato(getIt<ICandidatoRepositorio>()),
  );
  getIt.registerLazySingleton(
    () => VerificarDuplicidade(getIt<ICandidatoRepositorio>()),
  );
  getIt.registerLazySingleton(
    () => MergeCandidato(getIt<ICandidatoRepositorio>()),
  );
  getIt.registerLazySingleton<ListarVagas>(
    () => ListarVagas(getIt<IVagaRepositorio>()),
  );
  getIt.registerLazySingleton<SalvarVaga>(
    () => SalvarVaga(getIt<IVagaRepositorio>()),
  );
  getIt.registerLazySingleton<ListarCandidaturasPorVaga>(
    () => ListarCandidaturasPorVaga(getIt<ICandidaturaRepositorio>()),
  );
  getIt.registerLazySingleton<RanquearCandidatos>(() => RanquearCandidatos());
  // R1/R3 — Ranking IA por vaga
  getIt.registerLazySingleton(() => RankingService());
  getIt.registerLazySingleton(() => RankingRepositorioFirestore());
  // A1 — Agendamento de entrevistas
  getIt.registerLazySingleton(() => EntrevistaRepositorioFirestore());
}
