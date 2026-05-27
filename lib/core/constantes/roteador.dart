// Configuracao do GoRouter com regras de login.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rh_os/core/constantes/app_rotas.dart';

import 'package:rh_os/presentation/auth/tela_login.dart';
import 'package:rh_os/presentation/home/tela_home.dart';
import 'package:rh_os/presentation/mais/tela_mais.dart';
import 'package:rh_os/presentation/curriculos/tela_lista_curriculos.dart';
import 'package:rh_os/presentation/curriculos/tela_curriculo_completo.dart';
import 'package:rh_os/presentation/curriculos/tela_upload.dart';
import 'package:rh_os/presentation/perfil/tela_informacoes_perfil.dart';
import 'package:rh_os/presentation/perfil/tela_editar_campo.dart';
import 'package:rh_os/presentation/vagas/tela_lista_vagas.dart';
import 'package:rh_os/presentation/vagas/tela_criar_vaga.dart';
import 'package:rh_os/presentation/vagas/tela_detalhe_vaga.dart';
import 'package:rh_os/presentation/dashboard/tela_dashboard.dart';
import 'package:rh_os/presentation/admin/tela_gestao_usuarios.dart';
import 'package:rh_os/presentation/entrevistas/tela_entrevistas.dart';
import 'package:rh_os/presentation/notificacoes/tela_notificacoes.dart';

// Cria o roteador aplicando redirect conforme autenticacao.
GoRouter criarRoteador(SharedPreferences prefs) {
  return GoRouter(
    initialLocation: AppRotas.login,
    redirect: (BuildContext context, GoRouterState state) {
      // Autenticação unificada por 'usuario_uid' (Firebase Auth UID).
      final logado = prefs.getString('usuario_uid') != null;
      final naLogin = state.fullPath == AppRotas.login;

      if (!logado && !naLogin) return AppRotas.login;
      if (logado && naLogin) return AppRotas.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRotas.login,
        pageBuilder: (context, state) => _fade(state, const TelaLogin()),
      ),
      GoRoute(
        path: AppRotas.home,
        pageBuilder: (context, state) => _fade(state, const TelaHome()),
      ),
      GoRoute(
        path: AppRotas.mais,
        pageBuilder: (context, state) => _fade(state, const TelaMais()),
      ),
      GoRoute(
        path: AppRotas.notificacoes,
        pageBuilder: (context, state) => _fade(state, const TelaNotificacoes()),
      ),
      GoRoute(
        path: AppRotas.curriculos,
        pageBuilder: (context, state) =>
            _fade(state, const TelaListaCurriculos()),
      ),
      GoRoute(
        path: AppRotas.curriculoCompleto,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fade(state, TelaCurriculoCompleto(candidatoId: id));
        },
      ),
      GoRoute(
        path: AppRotas.upload,
        pageBuilder: (context, state) => _fade(state, const TelaUpload()),
      ),
      GoRoute(
        path: AppRotas.perfil,
        pageBuilder: (context, state) =>
            _fade(state, const TelaInformacoesPerfil()),
      ),
      GoRoute(
        path: AppRotas.editarCampo,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? const {};
          return _fade(
            state,
            TelaEditarCampo(
              campo: extra['campo']?.toString() ?? '',
              label: extra['label']?.toString() ?? '',
              valorAtual: extra['valorAtual']?.toString() ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRotas.vagas,
        pageBuilder: (context, state) => _fade(state, const TelaListaVagas()),
      ),
      GoRoute(
        path: AppRotas.novaVaga,
        pageBuilder: (context, state) => _fade(state, const TelaCriarVaga()),
      ),
      GoRoute(
        path: AppRotas.detalheVaga,
        pageBuilder: (context, state) {
          // idStr (String) é o identificador principal no Firestore.
          final idStr = state.pathParameters['id'] ?? '';
          return _fade(state, TelaDetalheVaga(vagaIdStr: idStr));
        },
      ),
      GoRoute(
        path: AppRotas.dashboard,
        pageBuilder: (context, state) => _fade(state, const TelaDashboard()),
      ),
      GoRoute(
        path: AppRotas.admin,
        pageBuilder: (context, state) =>
            _fade(state, const TelaGestaoUsuarios()),
      ),
      GoRoute(
        path: AppRotas.entrevistas,
        pageBuilder: (context, state) =>
            _fade(state, const TelaEntrevistas()),
      ),
    ],
  );
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 200),
  );
}
