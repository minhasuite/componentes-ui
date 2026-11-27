// v1.13.0 "confiança na IA e suíte": o que mudou desde a última visita (par do Ss::SinceLastVisitComponent). O cartão
// ao abrir: "Desde ontem às 18h: 3 pedidos novos, R$ 1.240 recebidos, 1 tarefa atrasada", com os números rolando
// (odômetro) e uma ação em cada item. A última visita fica num armazenamento que o app injeta ([SsLastVisit]).
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_badge.dart';
import '../ss_button.dart';
import '../ss_card.dart';
import '../ss_list.dart';
import '../ss_odometer.dart';
import '../ss_sheet.dart';
import '../ss_strings.dart';
import 'strings.dart';

/// Um item do resumo: o [value] que rola ("3", "R\$ 1.240,00") e o [label] ("pedidos novos").
class SsSinceItem {
  const SsSinceItem({
    required this.value,
    required this.label,
    this.icon = Icons.fiber_new_outlined,
    this.tone = SsTone.accent,
    this.onTap,
    this.actionLabel,
  });

  final String value;
  final String label;
  final IconData icon;
  final SsTone tone;

  /// A ação do item (abrir os pedidos novos). O texto é [actionLabel] ou "Ver".
  final VoidCallback? onTap;
  final String? actionLabel;
}

/// A última visita guardada pelo app (SharedPreferences, secure storage, o que ele já usa).
///
/// ```dart
/// final visita = SsLastVisit(read: (k) async => prefs.getString(k), write: (k, v) => prefs.setString(k, v));
/// final desde = await visita.load(); // nulo na 1ª vez
/// ```
class SsLastVisit {
  SsLastVisit({required this.read, required this.write, this.key = 'ss-last-visit'});

  final Future<String?> Function(String key) read;
  final Future<void> Function(String key, String value) write;

  /// A chave (a mesma do localStorage do web).
  final String key;

  /// A visita anterior, ou nulo na primeira.
  Future<DateTime?> load() async => DateTime.tryParse(await read(key) ?? '');

  /// Marca agora (ou [at]) como a última visita.
  Future<void> touch([DateTime? at]) => write(key, (at ?? DateTime.now()).toUtc().toIso8601String());
}

/// O cartão "desde a última visita". Some sozinho depois de [autoHide] (pausa com o leitor de tela ligado) ou no
/// "Entendi"; ao sumir, grava a visita em [store] e chama [onDismiss]. Sem itens, não desenha nada.
///
/// ```dart
/// SsSinceLastVisit(since: desde, store: visita, items: [
///   SsSinceItem(value: '3', label: 'pedidos novos', icon: Icons.receipt_long_outlined, onTap: abrirPedidos),
///   SsSinceItem(value: money(124000), label: 'recebidos', tone: SsTone.success),
///   SsSinceItem(value: '1', label: 'tarefa atrasada', tone: SsTone.warning, icon: Icons.schedule),
/// ])
/// ```
class SsSinceLastVisit extends StatefulWidget {
  const SsSinceLastVisit({
    super.key,
    required this.since,
    required this.items,
    this.store,
    this.onDismiss,
    this.autoHide = const Duration(seconds: 12),
    this.now,
    this.card = true,
  });

  final DateTime since;
  final List<SsSinceItem> items;
  final SsLastVisit? store;
  final VoidCallback? onDismiss;

  /// Nulo: só some no "Entendi".
  final Duration? autoHide;

  /// O "agora" do título (teste e catálogo).
  final DateTime? now;

  /// Falso: sem a moldura do card (dentro da folha do [showSsSinceLastVisit]).
  final bool card;

  /// "Desde ontem às 18h", "Desde segunda às 9h30", "Desde 12/11".
  static String label(DateTime since, {DateTime? now, SsTrustStrings t = SsTrustStrings.pt, SsStrings? s}) {
    final strings = s ?? SsStrings.pt;
    final n = (now ?? DateTime.now()).toLocal(), d = since.toLocal();
    final day = DateTime(d.year, d.month, d.day), today = DateTime(n.year, n.month, n.day);
    final days = today.difference(day).inDays;
    final time = t.clock(d);
    if (days <= 0) return SsTrustStrings.fill(t.sinceToday, {'time': time});
    if (days == 1) return SsTrustStrings.fill(t.sinceYesterday, {'time': time});
    if (days < 7) {
      return SsTrustStrings.fill(t.sinceWeekday, {'weekday': strings.weekdaysLong[d.weekday - 1], 'time': time});
    }
    return SsTrustStrings.fill(t.sinceDate, {'date': strings.formatDayMonth(d)});
  }

  @override
  State<SsSinceLastVisit> createState() => _SsSinceLastVisitState();
}

class _SsSinceLastVisitState extends State<SsSinceLastVisit> {
  Timer? _timer;
  var _gone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    final a = widget.autoHide;
    // Com o leitor de tela, o cartão não some sozinho (a pessoa pode não ter chegado nele).
    if (a == null || widget.items.isEmpty || MediaQuery.accessibleNavigationOf(context)) return;
    _timer = Timer(a, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_gone || !mounted) return;
    _timer?.cancel();
    setState(() => _gone = true);
    widget.store?.touch(widget.now);
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final s = SsStrings.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.medium;
    final title = SsSinceLastVisit.label(widget.since, now: widget.now, t: t, s: s);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: 18, color: c.accentText),
            SizedBox(width: d.space(8)),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  style: TextStyle(fontSize: AppType.set, fontWeight: FontWeight.w800, color: c.ink),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: d.space(4)),
        for (final it in widget.items) _Line(it),
        SizedBox(height: d.space(4)),
        Align(
          alignment: Alignment.centerRight,
          child: SsButton.text(label: t.sinceGotIt, onPressed: _dismiss),
        ),
      ],
    );
    return Semantics(
      container: true,
      label: t.sinceTitle,
      child: AnimatedSwitcher(
        duration: dur,
        switchInCurve: SsMotion.enter,
        switchOutCurve: SsMotion.exit,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SizeTransition(sizeFactor: a, alignment: Alignment.topCenter, child: child),
        ),
        child: _gone
            ? const SizedBox(key: ValueKey('gone'), width: double.infinity)
            : KeyedSubtree(
                key: const ValueKey('on'),
                child: widget.card ? SsCard(child: body) : body,
              ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.it);
  final SsSinceItem it;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final tone = it.tone.colors(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: d.minTarget),
      child: Row(
        children: [
          SsIconTile(it.icon, size: 32, tone: tone.solid),
          SizedBox(width: d.space(12)),
          Expanded(
            child: Semantics(
              label: '${it.value} ${it.label}',
              excludeSemantics: true,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: d.space(6),
                children: [
                  SsOdometer(it.value, size: AppType.lg, color: c.ink, rollIn: true),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      it.label,
                      style: TextStyle(fontSize: AppType.sub, color: c.ink2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (it.onTap != null)
            SsButton.text(label: it.actionLabel ?? t.sinceOpen, onPressed: it.onTap, trailingIcon: Icons.chevron_right),
        ],
      ),
    );
  }
}

/// O mesmo resumo numa folha (ao abrir o app depois de muito tempo, por exemplo).
Future<void> showSsSinceLastVisit(
  BuildContext context, {
  required DateTime since,
  required List<SsSinceItem> items,
  SsLastVisit? store,
  DateTime? now,
}) async {
  if (items.isEmpty) {
    await store?.touch(now);
    return;
  }
  await showSsSheet<void>(
    context,
    title: SsTrustStrings.of(context).sinceTitle,
    icon: Icons.history_rounded,
    child: Builder(
      builder: (sheet) => SsSinceLastVisit(
        since: since,
        items: items,
        now: now,
        card: false,
        autoHide: null,
        onDismiss: () => Navigator.of(sheet).pop(),
      ),
    ),
  );
  await store?.touch(now);
}
