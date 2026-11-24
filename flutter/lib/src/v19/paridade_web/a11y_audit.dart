// v1.9 · UX transversal: a auditoria de acessibilidade que os apps rodam nos testes de tela
// (só pelo `package:componentes_ui/testing.dart`; nunca no app).
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Confere a tela que já está montada no [tester] e falha com a lista do que achou:
///
/// 1. **alvo de toque** de pelo menos 48 × 48 em tudo que é tocável (o `androidTapTargetGuideline`);
/// 2. **rótulo** para o leitor de tela em todo botão e ícone tocável (o `labeledTapTargetGuideline`);
/// 3. **texto grande**: com o texto em [textScale] (1,6, o "fonte grande" do Android) a tela não estoura
///    (nenhum "RenderFlex overflowed" ou outro erro de layout).
///
/// ```dart
/// import 'package:componentes_ui/testing.dart';
///
/// testWidgets('pedidos: acessível', (tester) async {
///   await tester.pumpWidget(app(const PedidosScreen()));
///   await tester.pumpAndSettle();
///   await ssA11yAudit(tester);
/// });
/// ```
/// Desligue uma parte com `tapTargets:`, `labels:` ou `textScale: null`. O texto grande usa o
/// `platformDispatcher.textScaleFactorTestValue` (o `MaterialApp` lê dele) e volta ao normal no fim.
/// Com animação infinita na tela (skeleton, carregando), passe [settle] curto: o pump fica fixo nele.
Future<void> ssA11yAudit(
  WidgetTester tester, {
  bool tapTargets = true,
  bool labels = true,
  double? textScale = 1.6,
  Duration settle = const Duration(milliseconds: 300),
}) async {
  final problemas = <String>[];
  final semantics = tester.ensureSemantics();
  try {
    if (tapTargets) {
      final r = await androidTapTargetGuideline.evaluate(tester);
      if (!r.passed) problemas.add('Alvo de toque menor que 48 × 48:\n${r.reason}');
    }
    if (labels) {
      final r = await labeledTapTargetGuideline.evaluate(tester);
      if (!r.passed) problemas.add('Tocável sem rótulo para o leitor de tela:\n${r.reason}');
    }
  } finally {
    semantics.dispose();
  }
  if (textScale != null) {
    final erros = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (d) => erros.add(d.exceptionAsString().split('\n').first);
    try {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      await tester.pump();
      await tester.pump(settle);
    } finally {
      FlutterError.onError = original;
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    }
    await tester.pump();
    await tester.pump(settle);
    final e = tester.takeException();
    if (e != null) erros.add('$e'.split('\n').first);
    if (erros.isNotEmpty) {
      problemas.add('Com o texto em ${textScale}x a tela estoura:\n${erros.toSet().map((m) => '  • $m').join('\n')}');
    }
  }
  if (problemas.isNotEmpty) {
    fail('ssA11yAudit achou ${problemas.length} problema(s):\n\n${problemas.join('\n\n')}');
  }
}

/// O que a [ssA11yAudit] conta como texto grande (para o app escrever o teste dele com o mesmo valor).
const ssA11yLargeText = TextScaler.linear(1.6);
