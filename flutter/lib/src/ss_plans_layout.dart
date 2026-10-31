import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Tela de planos padrão da suíte. Arquivo idêntico em todos os apps: só usa o
// ColorScheme, então não depende dos tokens de cada um. Ao mudar aqui, copie
// para os outros apps.
//
// Ordem (a do minhas-viagens): plano atual, Mensal/Anual, um cartão por plano,
// "Comparar os planos" (tabela, a do meu-cultivo), letras miúdas, restaurar e
// gerenciar. O Max leva a cor de destaque (a ideia do meu-personal).

enum SsTier { free, pro, max }

/// Laranja do Max: a cor que puxa o olho para o plano completo.
const ssMaxColor = Color(0xFFFF8A4C);

Color ssTierColor(BuildContext context, SsTier tier) => switch (tier) {
  SsTier.free => Theme.of(context).colorScheme.onSurfaceVariant,
  SsTier.pro => Theme.of(context).colorScheme.primary,
  SsTier.max => ssMaxColor,
};

/// Um plano da vitrine.
class SsPlanOffer {
  const SsPlanOffer({
    required this.tier,
    required this.name,
    required this.features,
    this.price,
    this.priceNote,
    this.current = false,
    this.badge,
    this.ctaLabel,
    this.onBuy,
    this.busy = false,
    this.note,
  });

  final SsTier tier;
  final String name;

  /// "R$ 19,90/mês", "Grátis". Nulo enquanto a loja não respondeu.
  final String? price;

  /// Embaixo do preço ("Economia de 17% sobre 12 meses no mensal").
  final String? priceNote;
  final List<String> features;

  /// Plano que a pessoa já tem: vira estado, sem botão de compra.
  final bool current;

  /// Selo ao lado do nome ("14 dias grátis"). No Max, sem selo próprio, vai
  /// "Mais completo".
  final String? badge;

  /// "Assinar Pro", "Testar 14 dias grátis". Nulo = sem botão (Grátis).
  final String? ctaLabel;

  /// Nulo com [ctaLabel] = botão desligado (loja carregando ou indisponível).
  final VoidCallback? onBuy;
  final bool busy;

  /// Embaixo do botão: por que não dá para comprar, o que acontece depois do teste.
  final String? note;
}

/// Uma linha do comparativo: o recurso e o que cada plano dá ("3/mês", "∞", "—").
typedef SsPlanCompareRow = ({String label, String free, String pro, String max});

class SsPlansView extends StatelessWidget {
  const SsPlansView({
    super.key,
    required this.currentName,
    required this.offers,
    required this.compare,
    this.currentTier = SsTier.free,
    this.currentLines = const [],
    this.currentWarning,
    this.currentExtra,
    this.yearly,
    this.onYearly,
    this.yearlySavings = 0,
    this.highlightCompare,
    this.compareNames = const ['Grátis', 'Pro', 'Max'],
    this.footnote,
    this.onRestore,
    this.onManage,
    this.busy = false,
  });

  /// "Plano Pro".
  final String currentName;
  final SsTier currentTier;

  /// Renovação, teste, uso dos limites.
  final List<String> currentLines;

  /// Pagamento com problema, assinatura vencida.
  final String? currentWarning;

  /// Medidores ou avisos próprios do app, embaixo das linhas.
  final Widget? currentExtra;

  /// Nulo = o app só vende mensal (sem a chave Mensal/Anual).
  final bool? yearly;
  final ValueChanged<bool>? onYearly;
  final int yearlySavings;

  final List<SsPlanOffer> offers;
  final List<SsPlanCompareRow> compare;

  /// Linha do comparativo marcada (o recurso que trouxe a pessoa até aqui).
  final String? highlightCompare;

  /// Cabeçalho das colunas do comparativo (ex.: "Basic" no lugar de "Grátis").
  final List<String> compareNames;
  final String? footnote;
  final VoidCallback? onRestore;
  final VoidCallback? onManage;

  /// Confirmando a compra no servidor: bloqueia a tela.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final tierColor = ssTierColor(context, currentTier);
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _box(
              context,
              border: currentWarning != null ? s.error : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEU PLANO',
                    style: TextStyle(
                      color: s.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.workspace_premium, color: tierColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentName,
                          style: TextStyle(color: s.onSurface, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  if (currentWarning != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        currentWarning!,
                        style: TextStyle(color: s.error, fontWeight: FontWeight.w700),
                      ),
                    ),
                  for (final l in currentLines)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(l, style: TextStyle(color: s.onSurfaceVariant, fontSize: 13.5)),
                    ),
                  if (currentExtra != null) ...[const SizedBox(height: 10), currentExtra!],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (yearly != null && onYearly != null) ...[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: [
                    const ButtonSegment(value: false, label: Text('Mensal')),
                    ButtonSegment(value: true, label: Text(yearlySavings > 0 ? 'Anual · −$yearlySavings%' : 'Anual')),
                  ],
                  selected: {yearly!},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => onYearly!(v.first),
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (final o in offers) Padding(padding: const EdgeInsets.only(bottom: 12), child: SsPlanCard(o)),
            if (compare.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => showSsPlanCompare(
                  context,
                  compare,
                  current: currentTier,
                  highlight: highlightCompare,
                  names: compareNames,
                ),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Comparar os planos'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            if (footnote != null) ...[
              const SizedBox(height: 14),
              Text(footnote!, style: TextStyle(color: s.onSurfaceVariant, fontSize: 12.5)),
            ],
            if (onRestore != null || onManage != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (onRestore != null)
                    TextButton.icon(
                      onPressed: onRestore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restaurar compras'),
                    ),
                  if (onManage != null)
                    TextButton.icon(
                      onPressed: onManage,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Gerenciar assinatura'),
                    ),
                ],
              ),
            ],
          ],
        ),
        if (busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text('Confirmando sua assinatura…', style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Cartão de um plano: nome na cor do plano, preço, o que inclui e a ação.
class SsPlanCard extends StatelessWidget {
  const SsPlanCard(this.offer, {super.key});
  final SsPlanOffer offer;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final o = offer;
    final color = ssTierColor(context, o.tier);
    final max = o.tier == SsTier.max;
    final badge = o.badge ?? (max && !o.current ? 'Mais completo' : null);
    return _box(
      context,
      border: max || o.current ? color : null,
      width: max || o.current ? 2 : 1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                o.name,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
              ),
              if (badge != null) _pill(badge, color),
            ],
          ),
          if (o.price != null) ...[
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                o.price!,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: s.onSurface),
              ),
            ),
          ],
          if (o.priceNote != null) Text(o.priceNote!, style: TextStyle(color: s.onSurfaceVariant, fontSize: 12.5)),
          const SizedBox(height: 14),
          for (final f in o.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: color, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f, style: TextStyle(fontSize: 14, height: 1.3, color: s.onSurface)),
                  ),
                ],
              ),
            ),
          if (o.current) ...[
            const SizedBox(height: 6),
            Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: color, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    'Seu plano atual',
                    style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ] else if (o.ctaLabel != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: o.busy ? null : o.onBuy,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: o.busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(o.ctaLabel!),
              ),
            ),
          ],
          if (o.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(o.note!, style: TextStyle(color: s.onSurfaceVariant, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

/// Tabela Grátis × Pro × Max numa folha de baixo.
Future<void> showSsPlanCompare(
  BuildContext context,
  List<SsPlanCompareRow> rows, {
  SsTier current = SsTier.free,
  String? highlight,
  List<String> names = const ['Grátis', 'Pro', 'Max'],
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (ctx) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .85),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SsPlanCompareTable(rows, current: current, highlight: highlight, names: names),
      ),
    ),
  ),
);

class SsPlanCompareTable extends StatelessWidget {
  const SsPlanCompareTable(
    this.rows, {
    super.key,
    this.current = SsTier.free,
    this.highlight,
    this.names = const ['Grátis', 'Pro', 'Max'],
  });

  final List<SsPlanCompareRow> rows;
  final SsTier current;
  final String? highlight;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    Widget cell(String t, SsTier tier, {bool head = false}) {
      final on = tier == current;
      final color = head || on ? ssTierColor(context, tier) : (t == '—' ? s.onSurfaceVariant : s.onSurface);
      return Expanded(
        child: Text(
          t,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: head ? 13 : 13.5,
            fontWeight: head || on ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Comparar os planos',
          style: TextStyle(color: s.onSurface, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _box(
          context,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox.shrink()),
                    cell(names[0], SsTier.free, head: true),
                    cell(names[1], SsTier.pro, head: true),
                    cell(names[2], SsTier.max, head: true),
                  ],
                ),
              ),
              for (final r in rows)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: r.label == highlight ? s.primaryContainer : null,
                    border: Border(top: BorderSide(color: s.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          r.label,
                          style: TextStyle(color: s.onSurface, fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      cell(r.free, SsTier.free),
                      cell(r.pro, SsTier.pro),
                      cell(r.max, SsTier.max),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _pill(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(999)),
  child: Text(
    text,
    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
  ),
);

Widget _box(
  BuildContext context, {
  required Widget child,
  Color? border,
  double width = 1,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
}) {
  final s = Theme.of(context).colorScheme;
  return Container(
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: s.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border ?? s.outlineVariant.withValues(alpha: .6), width: width),
    ),
    child: child,
  );
}
