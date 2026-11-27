// v0.15: esconder valores no app (par do [data-privacy="on"] / ss-privacy do web).
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../motion.dart' show SsMotion;
import '../ss_strings.dart';

/// Modo privacidade: com [hidden], todo [SsAmount] abaixo vira "R$ •••" (o
/// leitor de tela diz "valor oculto") e todo [SsPrivate] fica borrado. Guardar
/// a escolha (prefs) e o botão de ligar são do app: [SsPrivacyToggle] é o olho
/// pronto. Ponha uma vez em volta do app (no `builder:` do MaterialApp).
///
/// `SsPrivacyScope(hidden: ref.watch(privacyProvider), child: child!)`
///
/// v1.13.0, modo discreto automático ([auto]): esconde também quando um dos sinais do app liga (celular virado
/// para baixo, tela compartilhada: [SsPrivacySignal], que o app alimenta pelos sensores dele) e, com
/// [SsPrivacyAuto.background], quando o app sai da frente (`AppLifecycleState` diferente de `resumed`). Com
/// [SsPrivacyAuto.blurSnapshot], o app inteiro fica desfocado nesse momento, para a miniatura da lista de apps
/// recentes não mostrar os valores (para garantir, o app pode ligar também o `FLAG_SECURE` no Android).
///
/// ```dart
/// final virado = SsPrivacySignal('face_down'); // o app liga pelo acelerômetro
/// SsPrivacyScope(hidden: escolha, auto: SsPrivacyAuto(signals: [virado]), child: child!)
/// ```
class SsPrivacyScope extends StatefulWidget {
  const SsPrivacyScope({super.key, required this.hidden, required this.child, this.auto});

  /// A escolha da pessoa (o olho).
  final bool hidden;
  final Widget child;

  /// v1.13.0: o modo discreto automático; nulo = só a escolha.
  final SsPrivacyAuto? auto;

  /// Valores escondidos aqui? Sem escopo, falso.
  static bool hiddenOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SsPrivacyInherited>()?.hidden ?? false;

  /// v1.13.0: por que o modo automático escondeu agora (share, background, face_down ou o motivo do sinal); vazio =
  /// não escondeu sozinho.
  static Set<String> autoReasonsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SsPrivacyInherited>()?.reasons ?? const {};

  @override
  State<SsPrivacyScope> createState() => _SsPrivacyScopeState();
}

/// v1.13.0: um sinal do modo discreto automático que o app liga e desliga (`sinal.value = true`). [reason] é a
/// chave do motivo (`share`, `face_down` ou uma do app).
class SsPrivacySignal extends ValueNotifier<bool> {
  SsPrivacySignal(this.reason, [super.value = false]);

  final String reason;
}

/// v1.13.0: o que liga o modo discreto automático do [SsPrivacyScope].
class SsPrivacyAuto {
  const SsPrivacyAuto({this.signals = const [], this.background = true, this.blurSnapshot = true});

  /// Os sinais do app (sensores, compartilhamento de tela).
  final List<ValueListenable<bool>> signals;

  /// Esconde os valores com o app fora da frente.
  final bool background;

  /// Desfoca o app inteiro fora da frente (a miniatura dos recentes).
  final bool blurSnapshot;
}

class _SsPrivacyScopeState extends State<SsPrivacyScope> with WidgetsBindingObserver {
  var _away = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen(widget.auto, true);
  }

  @override
  void didUpdateWidget(SsPrivacyScope old) {
    super.didUpdateWidget(old);
    if (old.auto?.signals != widget.auto?.signals) {
      _listen(old.auto, false);
      _listen(widget.auto, true);
    }
  }

  void _listen(SsPrivacyAuto? a, bool on) {
    for (final s in a?.signals ?? const <ValueListenable<bool>>[]) {
      on ? s.addListener(_changed) : s.removeListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final away = state != AppLifecycleState.resumed;
    if (away != _away && mounted) setState(() => _away = away);
  }

  @override
  void dispose() {
    _listen(widget.auto, false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.auto;
    final reasons = <String>{
      if (a != null && a.background && _away) 'background',
      if (a != null)
        for (final s in a.signals)
          if (s.value) s is SsPrivacySignal ? s.reason : 'signal',
    };
    final hidden = widget.hidden || reasons.isNotEmpty;
    Widget child = _SsPrivacyInherited(hidden: hidden, reasons: reasons, child: widget.child);
    if (a != null && a.blurSnapshot) {
      child = Stack(
        textDirection: TextDirection.ltr,
        children: [
          child,
          if (_away)
            Positioned.fill(
              child: ExcludeSemantics(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: ColoredBox(color: SsColors.of(context).page.withValues(alpha: .4)),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return child;
  }
}

class _SsPrivacyInherited extends InheritedWidget {
  const _SsPrivacyInherited({required this.hidden, required this.reasons, required super.child});

  final bool hidden;
  final Set<String> reasons;

  @override
  bool updateShouldNotify(_SsPrivacyInherited old) => old.hidden != hidden || !setEquals(old.reasons, reasons);
}

/// "R$ 1.234,56" → "R$ •••", "-1.234,56 €" → "••• €", "72%" → "•••%". O sinal
/// some junto (não entrega se é entrada ou saída).
String ssPrivacyMask(String text) {
  final primeiro = text.indexOf(RegExp(r'\d'));
  if (primeiro < 0) return text;
  final ultimo = text.lastIndexOf(RegExp(r'\d'));
  final prefix = text.substring(0, primeiro).replaceAll(RegExp('[+\\-−]'), '');
  return '$prefix•••${text.substring(ultimo + 1)}';
}

/// Borra [child] quando o [SsPrivacyScope] esconde os valores (gráfico,
/// número que não é [SsAmount]). O leitor de tela ouve só "valor oculto".
class SsPrivate extends StatelessWidget {
  const SsPrivate({super.key, required this.child, this.sigma = 7});

  final Widget child;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    if (!SsPrivacyScope.hiddenOf(context)) return child;
    return Semantics(
      label: SsStrings.of(context).hiddenValue,
      excludeSemantics: true,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        ),
      ),
    );
  }
}

/// O olho de mostrar/esconder valores (o `.ss-eye-on`/`.ss-eye-off` do web).
/// [hidden] é o estado atual; [onChanged] recebe o novo.
class SsPrivacyToggle extends StatelessWidget {
  const SsPrivacyToggle({super.key, required this.hidden, required this.onChanged, this.color});

  final bool hidden;
  final ValueChanged<bool> onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    return IconButton(
      tooltip: hidden ? s.showValues : s.hideValues,
      isSelected: hidden,
      onPressed: () => onChanged(!hidden),
      icon: AnimatedSwitcher(
        duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : SsMotion.short,
        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
        child: Icon(
          hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          key: ValueKey(hidden),
          color: color ?? SsColors.of(context).ink2,
        ),
      ),
    );
  }
}
