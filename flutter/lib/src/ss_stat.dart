import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'ss_list.dart';
import 'motion.dart';
import 'ss_charts.dart';

/// Valor em DM Mono com os centavos menores e apagados: "R$ 1.234" + ",56".
/// Sem vírgula seguida de 2 dígitos no fim, mostra o texto inteiro.
class SsAmount extends StatelessWidget {
  const SsAmount(this.text, {super.key, this.size = AppType.statNum, this.color, this.weight = FontWeight.w500});

  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;

  /// (inteiro, centavos) — centavos vazio quando não há.
  static (String, String) split(String text) {
    final m = RegExp(r'^(.*)(,\d{2})$').firstMatch(text);
    return m == null ? (text, '') : (m.group(1)!, m.group(2)!);
  }

  @override
  Widget build(BuildContext context) {
    final (main, cents) = split(text);
    final style = AppTheme.number(context, size: size, weight: weight, color: color ?? SsColors.of(context).ink);
    return Text.rich(
      TextSpan(
        text: main,
        style: style.copyWith(letterSpacing: -size * .03),
        children: [
          if (cents.isNotEmpty)
            TextSpan(
              text: cents,
              style: style.copyWith(fontSize: size * .58, color: style.color!.withValues(alpha: .55)),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
    );
  }
}

/// Variação numa pílula colorida pelo **sentido**, não pelo sinal: [good]
/// verde, ruim vermelho, `null` neutro. Despesa que caiu é `up: false, good: true`.
class SsDelta extends StatelessWidget {
  const SsDelta(this.text, {super.key, required this.up, bool? good, this.onDark = false}) : good = good ?? up;

  final String text;
  final bool up;
  final bool? good;

  /// Sobre o [SsAuroraCard]: fundo translúcido branco.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final (fg, bg) = switch (good) {
      _ when onDark => (AppColors.onDark, AppColors.onDark.withValues(alpha: .16)),
      true => (c.successText, AppColors.success.withValues(alpha: c.isDark ? .16 : .12)),
      false => (c.dangerText, AppColors.danger.withValues(alpha: c.isDark ? .18 : .12)),
      null => (c.muted, c.field),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 13, color: fg),
          const SizedBox(width: 2),
          Text(
            text,
            style: AppTheme.number(context, size: AppType.meta, weight: FontWeight.w500, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Card de indicador: rótulo, número grande, variação e minigráfico na base.
class SsStatCard extends StatelessWidget {
  const SsStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.delta,
    this.caption,
    this.spark,
    this.onTap,
    this.valueSize = 28,
    this.tone,
  });

  final String label;

  /// Texto pronto (`money(...)`); os centavos ficam menores ([SsAmount]).
  final String value;
  final IconData? icon;
  final SsDelta? delta;
  final String? caption;

  /// Série do minigráfico (sem eixo), da mais antiga para a mais nova.
  final List<double>? spark;
  final VoidCallback? onTap;
  final double valueSize;

  /// Cor do ícone (sucesso, aviso...); sem ela, a da marca.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final hasSpark = spark != null && spark!.length > 1;
    return SsPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
          border: c.isDark ? Border.all(color: c.line) : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, hasSpark ? 4 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        tone == null
                            ? Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(8)),
                                child: Icon(icon, size: 15, color: c.accentText),
                              )
                            : SsIconTile(icon!, size: 26, tone: tone),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Encolhe em vez de estourar na grade de 2 colunas em 360 dp.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SsAmount(value, size: valueSize),
                  ),
                  if (delta != null || caption != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ?delta,
                        if (delta != null && caption != null) const SizedBox(width: 6),
                        if (caption != null)
                          Flexible(
                            child: Text(
                              caption!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.muted, fontSize: AppType.meta),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (hasSpark) SsSparkline(spark!, height: 44, edgeToEdge: true),
          ],
        ),
      ),
    );
  }
}
