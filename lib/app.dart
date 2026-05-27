// Wrapper do MaterialApp.router com tema e rotas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/tema/app_tema.dart';

class RhOsApp extends ConsumerWidget {
  const RhOsApp({super.key, required this.roteador});

  final GoRouter roteador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.nomeApp,
      debugShowCheckedModeBanner: false,
      theme: AppTema.tema,
      routerConfig: roteador,
    );
  }
}
