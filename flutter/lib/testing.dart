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
// v1.9: a auditoria de acessibilidade para os testes de tela dos apps.
export 'src/v19/paridade_web/a11y_audit.dart';

/// Finders que entendem o `material_ui` (Flutter 3.50).
extension SsFinders on CommonFinders {
  /// Par do `find.byTooltip` (mesmo comportamento) que acha também o `Tooltip`
  /// do `material_ui`: o do `flutter_test` olha o `RawTooltip` pela semântica e,
  /// quando o tooltip tem `excludeFromSemantics: true` (o `SsHeaderAction`, por
  /// exemplo), só o `Tooltip` do Material do SDK, outro tipo desde o 3.50.
  Finder ssTooltip(Pattern message, {bool skipOffstage = true}) {
    bool bate(String? t) => t != null && (message is RegExp ? message.hasMatch(t) : t == message);
    // A mesma regra do find.byTooltip (um alvo só por tooltip): o RawTooltip pela
    // semântica; o Tooltip só quando ele não vai à semântica ou não tem mensagem.
    return byWidgetPredicate(
      (w) {
        if (w is Tooltip) {
          final texto = w.message ?? w.richMessage?.toPlainText() ?? '';
          if ((w.excludeFromSemantics ?? false) || texto.isEmpty) return bate(texto);
        }
        return w is RawTooltip && bate(w.semanticsTooltip);
      },
      description: 'tooltip "$message"',
      skipOffstage: skipOffstage,
    );
  }
}
