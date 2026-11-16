/// v1.0.1: ajudas de teste para os apps (só em `test/`, nunca em `lib/`).
///
/// ```dart
/// import 'package:componentes_ui/testing.dart';
///
/// await tester.tap(find.ssTooltip('Editar'));
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

export 'src/v100/fonts.dart' show ssPreloadFonts;

/// Finders que entendem o `material_ui` (Flutter 3.50).
extension SsFinders on CommonFinders {
  /// Par do `find.byTooltip` (mesmo comportamento) que acha também o `Tooltip`
  /// do `material_ui`: o do `flutter_test` olha o `RawTooltip` pela semântica e,
  /// quando o tooltip tem `excludeFromSemantics: true` (o `SsHeaderAction`, por
  /// exemplo), só o `Tooltip` do Material do SDK, outro tipo desde o 3.50.
  Finder ssTooltip(Pattern message, {bool skipOffstage = true}) {
    bool bate(String? t) => t != null && (message is RegExp ? message.hasMatch(t) : t == message);
    return byWidgetPredicate(
      (w) =>
          (w is Tooltip && bate(w.message ?? w.richMessage?.toPlainText())) ||
          (w is RawTooltip && bate(w.semanticsTooltip)),
      description: 'tooltip "$message"',
      skipOffstage: skipOffstage,
    );
  }
}
