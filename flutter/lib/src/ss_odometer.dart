import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'motion_view.dart';
import 'ss_stat.dart';

/// Número em DM Mono (centavos menores, como o [SsAmount]) que rola como
/// caça-níquel: cada dígito que muda é uma coluna 0–9 que gira até o novo e
/// assenta com mola (passa um pouco e volta), subindo quando o valor aumentou
/// e descendo quando caiu. As casas giram em cascata da direita para a
/// esquerda (35 ms entre elas), como o "vai um". Vírgula, ponto e "R$" ficam
/// parados; casa nova à esquerda entra com fade. Com [rollIn], os dígitos
/// partem do 0 quando o número entra na tela.
/// `SsOdometer(money(total))`.
class SsOdometer extends StatefulWidget {
  const SsOdometer(
    this.text, {
    super.key,
    this.size = AppType.statNum,
    this.color,
    this.weight = FontWeight.w500,
    this.rollIn = false,
  });

  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;

  /// Rola de 0 até o valor quando entra na tela (não só ao mudar).
  final bool rollIn;

  /// Valor do texto ("R$ -1.234,56" → -1234.56), para saber o sentido da rolagem.
  static double? parse(String text) => double.tryParse(text.replaceAll(RegExp(r'[^\d,-]'), '').replaceAll(',', '.'));

  @override
  State<SsOdometer> createState() => _SsOdometerState();
}

class _SsOdometerState extends State<SsOdometer> {
  bool _up = true;
  late int _lenAntes = _tamanho(widget.text);

  /// Com rollIn: já trocou os zeros pelo valor (entrou na tela).
  bool _rolou = false;

  @override
  void didUpdateWidget(SsOdometer old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    _lenAntes = _tamanho(old.text);
    _up = (SsOdometer.parse(widget.text) ?? 0) >= (SsOdometer.parse(old.text) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.rollIn || reduceMotion(context)) return _numero(context, widget.text);
    // Antes de aparecer, todo dígito é 0; no quadro seguinte ao que aparece,
    // cada coluna gira até o dela.
    return SsInView.visible(
      builder: (context, visible) {
        if (visible && !_rolou) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_rolou) setState(() => _rolou = true);
          });
        }
        return _numero(context, _rolou ? widget.text : widget.text.replaceAll(RegExp(r'\d'), '0'));
      },
    );
  }

  Widget _numero(BuildContext context, String text) {
    final (main, cents) = SsAmount.split(text);
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
    final pre = n - _tamanho(text);
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
                ordem: i < pre ? 0 : n - 1 - i,
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
int _tamanho(String text) => text.length - RegExp(r'^[^\d-]*').firstMatch(text)!.end;

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
    this.ordem = 0,
    required this.fadeIn,
    required this.animate,
  });

  final String char;
  final TextStyle style;
  final bool up;

  /// Casa contada da direita (0 = a última): atrasa o giro em cascata.
  final int ordem;
  final bool fadeIn;
  final bool animate;

  @override
  State<_Casa> createState() => _CasaState();
}

class _CasaState extends State<_Casa> with TickerProviderStateMixin {
  late final _roll = AnimationController(vsync: this, duration: _giro, value: 1);
  static const _giro = Duration(milliseconds: 560);
  Curve _curva = SsMotion.bounce;
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.fadeIn ? 0 : 1,
  );
  late double _from = (_digito(widget.char) ?? 0).toDouble();
  late double _to = _from;

  /// Posição na coluna (contínua; 10 é o 0 de novo).
  double get _pos => _from + (_to - _from) * _curva.transform(_roll.value);

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
    // Mais casas a girar, um pouco mais de tempo; a cascata atrasa as da esquerda.
    final atraso = math.min(widget.ordem, 8) * 35;
    final giro = _giro.inMilliseconds + 18 * passo.abs();
    _roll.duration = Duration(milliseconds: atraso + giro);
    _curva = Interval(atraso / (atraso + giro), 1, curve: SsMotion.bounce);
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
