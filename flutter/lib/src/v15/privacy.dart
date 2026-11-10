// v0.15: esconder valores no app (par do [data-privacy="on"] / ss-privacy do web).
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../ss_strings.dart';

/// Modo privacidade: com [hidden], todo [SsAmount] abaixo vira "R$ •••" (o
/// leitor de tela diz "valor oculto") e todo [SsPrivate] fica borrado. Guardar
/// a escolha (prefs) e o botão de ligar são do app: [SsPrivacyToggle] é o olho
/// pronto. Ponha uma vez em volta do app (no `builder:` do MaterialApp).
///
/// `SsPrivacyScope(hidden: ref.watch(privacyProvider), child: child!)`
class SsPrivacyScope extends InheritedWidget {
  const SsPrivacyScope({super.key, required this.hidden, required super.child});

  final bool hidden;

  /// Valores escondidos aqui? Sem escopo, falso.
  static bool hiddenOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SsPrivacyScope>()?.hidden ?? false;

  @override
  bool updateShouldNotify(SsPrivacyScope old) => old.hidden != hidden;
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
        duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
            ? Duration.zero
            : const Duration(milliseconds: 200),
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
