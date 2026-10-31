import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_stat.dart';

/// Número em DM Mono (centavos menores, como o [SsAmount]) em que só os
/// dígitos que mudam rolam: a coluna 0–9 desliza com mola até o dígito novo,
/// subindo quando o valor aumentou e descendo quando caiu. Vírgula, ponto e
/// "R$" ficam parados; casa nova à esquerda entra com fade.
/// `SsOdometer(money(total))`.
class SsOdometer extends StatefulWidget {
  const SsOdometer(this.text, {super.key, this.size = AppType.statNum, this.color, this.weight = FontWeight.w500});

  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;

  /// Valor do texto ("R$ -1.234,56" → -1234.56), para saber o sentido da rolagem.
  static double? parse(String text) => double.tryParse(text.replaceAll(RegExp(r'[^\d,-]'), '').replaceAll(',', '.'));

  @override
  State<SsOdometer> createState() => _SsOdometerState();
}

class _SsOdometerState extends State<SsOdometer> {
  bool _up = true;
  late int _lenAntes = _numero(widget.text);

  @override
  void didUpdateWidget(SsOdometer old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    _lenAntes = _numero(old.text);
    _up = (SsOdometer.parse(widget.text) ?? 0) >= (SsOdometer.parse(old.text) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final (main, cents) = SsAmount.split(widget.text);
    final s = widget.size;
    final base = AppTheme.number(
      context,
      size: s,
      weight: widget.weight,
      color: widget.color ?? SsColors.of(context).ink,
    );
    final mainStyle = base.copyWith(letterSpacing: -s * .03);
    final centsStyle = base.copyWith(fontSize: s * .58, color: base.color!.withValues(alpha: .55));
    final chars = [
      for (final ch in main.split('')) (ch, mainStyle),
      for (final ch in cents.split('')) (ch, centsStyle),
    ];
    final n = chars.length;
    final pre = n - _numero(widget.text);
    final animate = !reduceMotion(context);
    return Semantics(
      label: widget.text,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            for (var i = 0; i < n; i++)
              // "R$ " tem chave pela esquerda; o número, pela casa contada da direita
              // (a unidade continua unidade quando o número cresce).
              _Casa(
                key: i < pre ? ValueKey('p$i') : ValueKey(n - 1 - i),
                char: chars[i].$1,
                style: chars[i].$2,
                up: _up,
                fadeIn: animate && i >= pre && n - 1 - i >= _lenAntes,
                animate: animate,
              ),
          ],
        ),
      ),
    );
  }
}

/// Tamanho da parte numérica: tudo depois do prefixo sem dígito ("R$ ").
int _numero(String text) => text.length - RegExp(r'^[^\d-]*').firstMatch(text)!.end;

int? _digito(String ch) {
  final u = ch.codeUnitAt(0) - 0x30;
  return ch.length == 1 && u >= 0 && u <= 9 ? u : null;
}

class _Casa extends StatefulWidget {
  const _Casa({
    super.key,
    required this.char,
    required this.style,
    required this.up,
    required this.fadeIn,
    required this.animate,
  });

  final String char;
  final TextStyle style;
  final bool up;
  final bool fadeIn;
  final bool animate;

  @override
  State<_Casa> createState() => _CasaState();
}

class _CasaState extends State<_Casa> with TickerProviderStateMixin {
  late final _roll = AnimationController(vsync: this, duration: const Duration(milliseconds: 560), value: 1);
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.fadeIn ? 0 : 1,
  );
  late double _from = (_digito(widget.char) ?? 0).toDouble();
  late double _to = _from;

  /// Posição na coluna (contínua; 10 é o 0 de novo).
  double get _pos => _from + (_to - _from) * Curves.easeOutBack.transform(_roll.value);

  @override
  void initState() {
    super.initState();
    if (widget.fadeIn) _fade.forward();
  }

  @override
  void didUpdateWidget(_Casa old) {
    super.didUpdateWidget(old);
    final d = _digito(widget.char);
    if (d == null || widget.char == old.char) return;
    if (_digito(old.char) == null || !widget.animate) {
      _from = _to = d.toDouble();
      _roll.value = 1;
      return;
    }
    final atual = _pos;
    final alvo = atual.round();
    // Subindo, 9 → 0 passa por 10; descendo, 0 → 9 passa por -1.
    final passo = widget.up ? (d - alvo) % 10 : -((alvo - d) % 10);
    _from = atual;
    _to = (alvo + passo).toDouble();
    _roll.forward(from: 0);
  }

  @override
  void dispose() {
    _roll.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.style;
    Widget child;
    if (_digito(widget.char) == null) {
      child = Text(widget.char, style: st);
    } else {
      child = AnimatedBuilder(
        animation: _roll,
        builder: (_, _) {
          final p = _pos;
          final b = p.floor();
          return ClipRect(
            child: Stack(
              children: [
                Opacity(opacity: 0, child: Text('0', style: st)),
                for (var k = b - 1; k <= b + 2; k++)
                  Positioned.fill(
                    // Só o '0' invisível dá a linha de base: a coluna em movimento não conta.
                    child: IgnoreBaseline(
                      child: FractionalTranslation(
                        translation: Offset(0, (k - p) * 1.2), // 20% de folga entre um dígito e o próximo
                        child: Text('${k % 10}', style: st),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }
    return FadeTransition(opacity: _fade, child: child);
  }
}
