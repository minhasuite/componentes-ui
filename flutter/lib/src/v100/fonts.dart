import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/painting.dart' show FontWeight;

/// v1.0: carrega de uma vez todas as fontes empacotadas (Manrope, DM Mono e a
/// fonte de exibição) e espera terminar.
///
/// Para o `test/flutter_test_config.dart` dos apps e do pacote: desde o Flutter
/// 3.50, a fonte que termina de carregar no meio de um teste agenda o aviso
/// "fontes do sistema mudaram" e o `testWidgets` reprova com "An animation is
/// still running even after the widget tree was disposed". Carregando antes, o
/// aviso chega fora dos testes.
///
/// Precisa de um binding já iniciado (nos testes, o `TestWidgetsFlutterBinding`):
///
/// ```dart
/// Future<void> testExecutable(FutureOr<void> Function() testMain) async {
///   TestWidgetsFlutterBinding.ensureInitialized();
///   await ssPreloadFonts();
///   await testMain();
/// }
/// ```
Future<void> ssPreloadFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final w in const [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800]) {
    GoogleFonts.manrope(fontWeight: w);
  }
  for (final w in const [FontWeight.w400, FontWeight.w500]) {
    GoogleFonts.dmMono(fontWeight: w);
  }
  for (final w in const [FontWeight.w800, FontWeight.w900]) {
    GoogleFonts.bigShouldersDisplay(fontWeight: w);
  }
  await GoogleFonts.pendingFonts();
  // O aviso de fontes do sistema é uma mensagem assíncrona da engine.
  await Future<void>.delayed(const Duration(milliseconds: 50));
}
