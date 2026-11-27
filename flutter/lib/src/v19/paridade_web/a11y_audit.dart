// v1.9 · UX transversal: a auditoria de acessibilidade que os apps rodam nos testes de tela
// (só pelo `package:componentes_ui/testing.dart`; nunca no app).
import 'dart:async';

import 'package:flutter/foundation.dart';
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
///
/// v1.9.1: com o `FlutterError.onError` trocado pelo teste por um que não repassa ao binding (engole erro de
/// layout, por exemplo), a falha não é lançada (o binding do `flutter_test` ficaria esperando até o tempo
/// limite): é registrada direto no teste, que falha ao terminar com a mesma lista, e a função volta.
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
    final msg = 'ssA11yAudit achou ${problemas.length} problema(s):\n\n${problemas.join('\n\n')}';
    if (_bindingOuve(tester)) fail(msg);
    (debugSsA11yAuditReporter ?? _registrarNoTeste)(
      TestFailure(
        '$msg\n\n(O FlutterError.onError do teste não repassa ao binding: a falha foi registrada direto '
        'no teste, sem lançar, para não travar até o tempo limite.)',
      ),
    );
  }
}

/// Nos testes do pacote: quem recebe a falha quando o `FlutterError.onError` do teste não repassa ao
/// binding. Nulo: registra no teste (pela zona de fora da do binding).
@visibleForTesting
void Function(TestFailure falha)? debugSsA11yAuditReporter;

class _Sonda {
  const _Sonda();
}

/// O `FlutterError.onError` de agora leva o erro ao binding? Se não leva, uma falha lançada some no
/// handler do teste e o binding do `flutter_test` espera para sempre o erro que nunca chega.
bool _bindingOuve(WidgetTester tester) {
  // Erro que já estava pendente: o binding termina o teste com ele (lançar não trava).
  if (tester.takeException() case final pendente?) {
    FlutterError.reportError(FlutterErrorDetails(exception: pendente, library: 'ssA11yAudit'));
    return true;
  }
  FlutterError.reportError(const FlutterErrorDetails(exception: _Sonda(), library: 'ssA11yAudit'));
  return tester.takeException() is _Sonda;
}

/// Marca o teste como falho pela zona de fora da do binding (a do `package:test`), como o próprio
/// `flutter_test` faz ao fim do teste.
void _registrarNoTeste(TestFailure falha) {
  final zonaDoBinding = Zone.current.errorZone;
  (zonaDoBinding.parent ?? Zone.root).handleUncaughtError(falha, StackTrace.current);
}

/// O que a [ssA11yAudit] conta como texto grande (para o app escrever o teste dele com o mesmo valor).
const ssA11yLargeText = TextScaler.linear(1.6);
