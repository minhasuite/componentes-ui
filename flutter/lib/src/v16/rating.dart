// v0.16: estrelas (par do .ss-stars / Ss::RatingComponent da gem).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_strings.dart';

/// Nota em estrelas, de 0 a [max] (5): leitura aceita meia ("4,5" pinta
/// metade da 5ª); com [onChanged], cada estrela vira um botão (alvo de 48,
/// "3 estrelas" para o leitor de tela) e o grupo responde a deslizar para
/// cima/baixo como um ajuste. A cor é o âmbar das estrelas do web
/// (`.ss-stars`), a trilha o da linha.
///
/// `SsRating(4.5)` · `SsRating(nota, size: 32, onChanged: (v) => setState(() => nota = v))`
class SsRating extends StatelessWidget {
  const SsRating(this.value, {super.key, this.max = 5, this.size = 18, this.onChanged, this.label});

  final double value;
  final int max;
  final double size;

  /// Nota escolhida (1 a [max], inteira). Nulo = só leitura.
  final ValueChanged<int>? onChanged;

  /// Para o leitor de tela. Padrão: [SsStrings.ratingOf] ("Nota 4,5 de 5").
  final String? label;

  static const _cor = AppColors.aquecFg;

  String _num(BuildContext context, double v) {
    final f = SsFormats.of(context);
    return v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1).replaceAll('.', f.decimalSeparator);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final v = value.clamp(0, max).toDouble();
    final texto = label ?? s.ratingOf(_num(context, v), max);
    final trilha = c.isDark ? c.muted2 : AppColors.muted2Light;
    Widget estrela(int i) {
      final cheio = (v - i).clamp(0.0, 1.0);
      return SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Icon(Icons.star_rounded, size: size, color: trilha),
            if (cheio > 0)
              ClipRect(
                clipper: _Fracao(cheio),
                child: Icon(Icons.star_rounded, size: size, color: _cor),
              ),
          ],
        ),
      );
    }

    if (onChanged == null) {
      return Semantics(
        label: texto,
        excludeSemantics: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < max; i++) estrela(i)]),
      );
    }
    final atual = v.round();
    void muda(int n) {
      final novo = n.clamp(1, max);
      if (novo == atual) return;
      HapticFeedback.selectionClick();
      onChanged!(novo);
    }

    final alvo = math.max(size, d.minTarget);
    return Semantics(
      label: texto,
      value: s.starCount(atual),
      increasedValue: atual < max ? s.starCount(atual + 1) : null,
      decreasedValue: atual > 1 ? s.starCount(atual - 1) : null,
      onIncrease: atual < max ? () => muda(atual + 1) : null,
      onDecrease: atual > 1 ? () => muda(atual - 1) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++)
            Semantics(
              button: true,
              selected: i < atual,
              label: s.starCount(i + 1),
              excludeSemantics: true,
              child: SsPressable(
                onTap: () => muda(i + 1),
                scale: .85,
                child: SizedBox(
                  width: math.max(size + 4, alvo * .75),
                  height: alvo,
                  child: Center(child: estrela(i)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Fracao extends CustomClipper<Rect> {
  _Fracao(this.f);
  final double f;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * f, size.height);

  @override
  bool shouldReclip(_Fracao old) => old.f != f;
}
