import 'dart:async';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flutter 3.50: carrega as fontes antes de qualquer teste (ver [ssPreloadFonts]).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await ssPreloadFonts();
  await testMain();
}
