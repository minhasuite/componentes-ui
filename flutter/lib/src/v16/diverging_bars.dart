// v0.16: barras divergentes (par do Ss::DivergingBarsComponent da gem).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion_view.dart';
import '../ss_strings.dart';

/// Uma linha do [SsDivergingBars]: nome, valor (com sinal) e detalhe opcional.
@immutable
class SsDivergingBar {
  const SsDivergingBar(this.label, this.value, {this.detail});

  final String label;
  final double value;

  /// Linha apagada embaixo do nome ("+32% · 9% da cesta").
  final String? detail;
}

/// Barras para os dois lados de um eixo no meio: o que subiu vai para a
/// direita, o que caiu para a esquerda, com o tamanho proporcional ao maior
/// |valor|. Nome em cima da barra (nunca espremido) e o valor com sinal em DM
/// Mono à direita. Por padrão subir é ruim (vermelho) e cair é bom (verde):
/// inflação, gasto por categoria; [upIsGood] inverte (receita, economia). As
/// barras crescem do eixo em cascata quando entram na tela. O web é o
/// `Ss::DivergingBarsComponent`.
///
/// `SsDivergingBars(items: [SsDivergingBar('Café', 1.8, detail: '+32%'), SsDivergingBar('Tomate', -0.6)], unit: 'p.p.')`
class SsDivergingBars extends StatelessWidget {
  const SsDivergingBars({super.key, required this.items, this.format, this.unit, this.upIsGood = false});

  final List<SsDivergingBar> items;

  /// Texto do valor. Padrão: sinal (+/−) e 1 casa no separador do idioma.
  final String Function(double value)? format;

  /// Depois do valor padrão ("+1,8 p.p."). Ignorado com [format].
  final String? unit;
  final bool upIsGood;

  /// "+1,8" / "−0,6" / "0" no separador decimal de [f].
  static String signed(double v, [SsFormats f = SsFormats.brl]) {
    final n = v.abs().toStringAsFixed(1).replaceAll('.', f.decimalSeparator);
    final zero = v.abs() < .05;
    return zero ? '0' : '${v > 0 ? '+' : '−'}$n';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final f = SsFormats.of(context);
    final maxAbs = math.max(items.map((e) => e.value.abs()).reduce(math.max), 1e-9);
    String texto(double v) => format?.call(v) ?? '${signed(v, f)}${unit == null ? '' : ' $unit'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, it) in items.indexed)
          Builder(
            builder: (context) {
              final bom = it.value == 0 ? null : (it.value > 0) == upIsGood;
              final tinta = bom == null ? c.muted : (bom ? c.successText : c.dangerText);
              final barra = bom == null ? c.muted2 : (bom ? AppColors.success : AppColors.danger);
              return Semantics(
                label: '${it.label}: ${texto(it.value)}${it.detail == null ? '' : ', ${it.detail}'}',
                excludeSemantics: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: d.space(6)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              it.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: d.font(AppType.set),
                              ),
                            ),
                          ),
                          SizedBox(width: d.space(8)),
                          Text(
                            texto(it.value),
                            style: AppTheme.number(context, size: d.font(AppType.meta), color: tinta),
                          ),
                        ],
                      ),
                      if (it.detail != null)
                        Text(
                          it.detail!,
                          style: TextStyle(color: c.muted, fontSize: d.font(AppType.meta)),
                        ),
                      SizedBox(height: d.space(4)),
                      SizedBox(
                        height: 8,
                        child: SsTweenInView(
                          end: 1,
                          duration: Duration(milliseconds: 500 + i * 60),
                          builder: (_, t, _) => CustomPaint(
                            size: Size.infinite,
                            painter: _Divergente(it.value / maxAbs * t, barra, c.field, c.muted2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Divergente extends CustomPainter {
  _Divergente(this.fracao, this.cor, this.trilha, this.eixo);
  final double fracao;
  final Color cor;
  final Color trilha;
  final Color eixo;

  @override
  void paint(Canvas canvas, Size size) {
    final meio = size.width / 2;
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, r), Paint()..color = trilha);
    final w = meio * fracao.abs().clamp(0.0, 1.0);
    final rect = fracao >= 0 ? Rect.fromLTWH(meio, 0, w, size.height) : Rect.fromLTWH(meio - w, 0, w, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, r), Paint()..color = cor);
    canvas.drawLine(
      Offset(meio, -2),
      Offset(meio, size.height + 2),
      Paint()
        ..color = eixo
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_Divergente old) => old.fracao != fracao || old.cor != cor || old.trilha != trilha;
}
