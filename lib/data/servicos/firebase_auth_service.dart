// Servico de autenticacao via Firebase Auth.

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class FirebaseAuthService {
  // Cliente FirebaseAuth.
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  // Autentica um usuario com e-mail e senha.
  Future<fb.UserCredential?> login(String email, String senha) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
    } on fb.FirebaseAuthException catch (e, st) {
      debugPrint('[FirebaseAuth] Erro login: ${e.code} — ${e.message}');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'FirebaseAuth.login: ${e.code}');
      return null;
    }
  }

  // Cria um novo usuario no Firebase Auth.
  Future<fb.UserCredential?> criarUsuario(String email, String senha) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
    } on fb.FirebaseAuthException catch (e, st) {
      debugPrint('[FirebaseAuth] Erro criar: ${e.code} — ${e.message}');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'FirebaseAuth.criarUsuario: ${e.code}');
      return null;
    }
  }

  // Realiza logout do usuario atual.
  Future<void> logout() async => _auth.signOut();

  // Usuario autenticado (ou null).
  fb.User? get usuarioAtual => _auth.currentUser;

  // UID do usuario autenticado (ou null).
  String? get uid => _auth.currentUser?.uid;

  // Stream do estado de autenticacao.
  Stream<fb.User?> get estadoAuth => _auth.authStateChanges();
}
