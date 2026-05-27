// ThemeData central do app.

import 'package:flutter/material.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/tema/app_estilos.dart';

abstract class AppTema {
  // Tema base reutilizado em toda a UI.
  static ThemeData get tema => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppCores.primaria,
          primary: AppCores.primaria,
          secondary: AppCores.cta,
          surface: AppCores.fundoCard,
        ),
        scaffoldBackgroundColor: AppCores.fundoPrincipal,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppCores.primaria,
          foregroundColor: AppCores.textoClaro,
          elevation: 0,
          titleTextStyle: AppEstilos.tituloAppBar,
          iconTheme: IconThemeData(color: AppCores.textoClaro),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppCores.cta,
            foregroundColor: AppCores.fundoCard,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: AppEstilos.textoBotao,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppCores.fundoInput,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppCores.primaria, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          hintStyle: const TextStyle(color: AppCores.textoSecundario),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardThemeData(
          color: AppCores.fundoCard,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0),
          thickness: 1,
          space: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppCores.primaria,
          selectedItemColor: AppCores.cta,
          unselectedItemColor: AppCores.textoClaro,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppCores.fundoInput,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: AppCores.textoPrincipal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppCores.primaria,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppCores.cta,
          foregroundColor: AppCores.fundoCard,
        ),
      );
}
