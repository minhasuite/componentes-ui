import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'density.dart';
import 'ss_stat.dart';

/// Linha de lista com nome + valor sem espremer o nome: o nome vai até 2
/// linhas, o valor fica à direita com no máximo 40% da largura (encolhe, não
/// quebra "R$ 2.231,70") e desce para baixo do nome com a fonte do sistema
/// ampliada (> 1,15×). [details] entra embaixo do subtítulo (medidor, selo);
/// [trailing] é a ação no fim (botão, menu). Diferente do [SsListItem] (uma
/// linha e sem ação) e do [SsValueRow] (rótulo … valor de recibo).
///
/// O valor conta de 0 quando a linha entra na tela e rola ao mudar.
///
/// `SsValueTile(title: 'Café torrado', subtitle: 'Melitta · 500 g', value: money(1890))`
class SsValueTile extends StatelessWidget {
  const SsValueTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.details,
    this.value,
    this.valueColor,
    this.valueNote,
    this.valueNoteColor,
    this.trailing,
    this.onTap,
    this.padding,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final Widget? details;
  final String? value;
  final Color? valueColor;

  /// Texto pequeno abaixo do valor ("-12%", "/mês").
  final String? valueNote;
  final Color? valueNoteColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Nulo: `padX` × `rowPadV` da [SsDensity] (16 × 10 no padrão).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final below = MediaQuery.textScalerOf(context).scale(10) > 11.5;
    Widget? valueBox;
    if (value != null) {
      valueBox = Column(
        crossAxisAlignment: below ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: below ? Alignment.centerLeft : Alignment.centerRight,
            child: SsAmount(value!, size: AppType.body, color: valueColor, countUp: true, roll: true),
          ),
          if (valueNote != null)
            Text(
              valueNote!,
              textAlign: below ? TextAlign.start : TextAlign.end,
              style: TextStyle(color: valueNoteColor ?? c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w700),
            ),
        ],
      );
    }
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: c.ink, fontWeight: FontWeight.w700, fontSize: d.font(AppType.body)),
        ),
        if ((subtitle ?? '').isNotEmpty)
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.muted, fontSize: AppType.meta),
          ),
        if (details != null) ...[const SizedBox(height: 4), details!],
        if (below && valueBox != null) ...[const SizedBox(height: 4), valueBox],
      ],
    );
    final row = Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: d.padX, vertical: d.rowPadV),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          children: [
            if (leading != null) ...[leading!, SizedBox(width: d.gap)],
            Expanded(child: text),
            if (!below && valueBox != null) ...[
              SizedBox(width: d.gap),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * .4),
                child: valueBox,
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          ],
        ),
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
