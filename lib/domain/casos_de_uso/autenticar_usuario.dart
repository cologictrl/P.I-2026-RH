// Caso de uso de autenticacao com Firebase e perfil local.

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/data/servicos/auditoria_service.dart';
import 'package:rh_os/data/servicos/firebase_auth_service.dart';
import 'package:rh_os/domain/entidades/usuario.dart';
import 'package:rh_os/domain/repositorios/i_usuario_repositorio.dart';

class AutenticarUsuario {
  // Dependencias de autenticacao e repositorio.
  const AutenticarUsuario(this._authService, this._repositorio);

  final FirebaseAuthService _authService;

  final IUsuarioRepositorio _repositorio;

  Future<Usuario?> executar(String email, String senha) async {
    try {
      debugPrint('[Auth] Tentando login via Firebase: ${email.trim()}');

      final credencial = await _authService.login(email.trim(), senha);
      if (credencial == null) {
        debugPrint('[Auth] Firebase Auth: credenciais inválidas');
        return null;
      }

      debugPrint('[Auth] Firebase Auth OK. UID: ${credencial.user?.uid}');

      final usuario = await _repositorio.buscarPorEmail(
        email.trim().toLowerCase(),
      );
      if (usuario == null) {
        debugPrint('[Auth] Perfil não encontrado no Firestore: $email');
        return null;
      }

      // Persiste dados de sessao localmente (apenas 'usuario_uid' e 'usuario_perfil').
      final uid = credencial.user!.uid;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario_uid', uid);
      await prefs.setString('usuario_perfil', usuario.perfil);
      await prefs.setString('usuario_logado_perfil', usuario.perfil);

      debugPrint('[Auth] Login completo. Perfil: ${usuario.perfil}');

      // Q3 — Auditoria: registra login bem-sucedido.
      getIt<AuditoriaService>().registrar(
        uid: uid,
        acao: 'login',
        detalhes: email.trim(),
      );

      return usuario;
    } catch (e, st) {
      debugPrint('[Auth] Erro inesperado: $e\n$st');
      return null;
    }
  }

  Future<void> sair() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_uid');
    await prefs.remove('usuario_perfil');
    await prefs.remove('usuario_logado_perfil');
  }
}
