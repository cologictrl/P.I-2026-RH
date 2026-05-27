// Entrada da aplicacao: inicializa Firebase, DI, seed e navegação.

import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rh_os/app.dart';
import 'package:rh_os/core/constantes/roteador.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/data/banco/firebase_seed.dart';
import 'package:rh_os/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Q2 — Crashlytics: captura erros Flutter e erros Dart assíncronos.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await configurarDependencias();

  await executarFirebaseSeedSeNecessario();

  final prefs = await SharedPreferences.getInstance();
  final roteador = criarRoteador(prefs);

  runApp(ProviderScope(child: RhOsApp(roteador: roteador)));
}
