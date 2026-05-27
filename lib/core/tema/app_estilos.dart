// Estilos tipograficos padrao da UI.

import 'package:flutter/material.dart';
import 'package:rh_os/core/tema/app_cores.dart';

abstract class AppEstilos {
  static const tituloPrincipal = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppCores.textoClaro,
  );

  static const tituloAppBar = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppCores.textoClaro,
  );

  static const headerSecao = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppCores.textoPrincipal,
  );

  static const valorCampo = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppCores.textoPrincipal,
  );

  static const labelCampo = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppCores.textoSecundario,
  );

  static const textoBotao = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppCores.fundoCard,
    letterSpacing: 1.2,
  );
}
