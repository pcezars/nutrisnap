// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

// Nossa cor primária
const Color corPrimaria = Colors.green;

final ThemeData appTheme = ThemeData(
  // 1. Defina a paleta de cores
  colorScheme: ColorScheme.fromSeed(
    seedColor: corPrimaria, // Nossa cor base
    brightness: Brightness.light,
    primary: corPrimaria,
  ),

  // 2. Defina o estilo da AppBar (para ser consistente)
  appBarTheme: const AppBarTheme(
    backgroundColor: corPrimaria, // Cor de fundo
    foregroundColor: Colors.white, // Cor do texto/ícones (branco)
    elevation: 4.0,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),

  // 3. Defina o estilo do Botão Flutuante (FAB)
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: corPrimaria,
    foregroundColor: Colors.white,
  ),

  // 4. Defina o estilo dos Botões Elevados (Salvar, etc.)
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: corPrimaria, // Cor de fundo
      foregroundColor: Colors.white, // Cor do texto
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),
  ),

  // 5. Defina o tema dos campos de texto (TextField)
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: corPrimaria, width: 2.0),
    ),
    labelStyle: const TextStyle(color: Colors.black54),
  ),

  // 6. Tema dos Cards
  cardTheme: CardThemeData(
    elevation: 3,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
);