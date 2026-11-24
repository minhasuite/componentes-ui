// v1.9 · paridade_app: novidades (par do Ss::WhatsNewComponent).
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../motion.dart';
import '../../ss_sheet.dart';
import '../../ss_strings.dart';
import 'comum.dart';

/// Uma novidade. O [id] é estável (é ele que fica guardado como visto).
class SsWhatsNewItem {
  const SsWhatsNewItem({required this.id, required this.title, this.date, this.text, this.onTap});

  final String id;
  final String title;
  final DateTime? date;
  final String? text;

  /// Abre a novidade (o `url:` do web). A folha fecha antes.
  final VoidCallback? onTap;
}

/// Novidades: o sino com ponto vermelho quando há item não visto; tocar abre
/// a folha com a lista (data e o selo "novo" nos não vistos) e marca tudo
/// como visto. Com [autoShow], a folha abre sozinha uma vez quando chega
/// novidade (o "mostrar uma vez"). O "já vi" fica no [store] na chave
/// `ss-whats-new:<id>`, com a lista de ids em JSON, como o `localStorage` do
/// web. [items] do mais novo para o mais antigo. Par do
/// `Ss::WhatsNewComponent` (lá é um popover).
///
/// `SsWhatsNew(id: 'financeiro', store: prefsStore, items: novidades)` (no `actions` do topo)
class SsWhatsNew extends StatefulWidget {
  const SsWhatsNew({
    super.key,
    required this.id,
    required this.items,
    required this.store,
    this.title,
    this.autoShow = false,
  });

  final String id;
  final List<SsWhatsNewItem> items;
  final SsSeenStore store;

  /// Padrão: [SsStrings.helpNews] ("Novidades").
  final String? title;
  final bool autoShow;

  static String keyFor(String id) => 'ss-whats-new:$id';

  /// Ids já vistos guardados no [store].
  static Future<Set<String>> seenIds(SsSeenStore store, String id) async {
    final raw = await store.read(keyFor(id));
    if (raw == null) return {};
    try {
      return {for (final v in jsonDecode(raw) as List) '$v'};
    } catch (_) {
      return {};
    }
  }

  @override
  State<SsWhatsNew> createState() => _SsWhatsNewState();
}

class _SsWhatsNewState extends State<SsWhatsNew> {
  Set<String>? _vistos;

  int get _naoVistas => _vistos == null ? 0 : widget.items.where((i) => !_vistos!.contains(i.id)).length;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final v = await SsWhatsNew.seenIds(widget.store, widget.id);
    if (!mounted) return;
    setState(() => _vistos = v);
    if (widget.autoShow && _naoVistas > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _abrir();
      });
    }
  }

  Future<void> _abrir() async {
    final antes = {...?_vistos};
    // Marca como visto ao abrir (como o web), e a folha ainda mostra o "novo".
    final todos = [for (final i in widget.items) i.id];
    setState(() => _vistos = todos.toSet());
    await widget.store.write(SsWhatsNew.keyFor(widget.id), jsonEncode(todos));
    if (!mounted) return;
    await showSsSheet<void>(
      context,
      title: widget.title ?? SsStrings.of(context).helpNews,
      child: SsWhatsNewList(items: widget.items, seen: antes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final n = _naoVistas;
    final titulo = widget.title ?? s.helpNews;
    return Semantics(
      button: true,
      label: n > 0 ? '$titulo, ${s.helpNewsUnseen(n)}' : titulo,
      excludeSemantics: true,
      child: IconButton(
        tooltip: titulo,
        onPressed: _abrir,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none_rounded, color: c.ink2),
            if (n > 0)
              Positioned(
                top: 1,
                right: 1,
                child: SsPop(
                  active: true,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: c.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A lista da folha do [SsWhatsNew] (data, selo "NOVO" nos ids fora de
/// [seen], título e texto; item com toque fecha a folha e abre). Pública para
/// uma tela "Novidades" própria ou a folha montada à mão.
class SsWhatsNewList extends StatelessWidget {
  const SsWhatsNewList({super.key, required this.items, this.seen = const {}});
  final List<SsWhatsNewItem> items;

  /// Ids já vistos (sem o selo "NOVO").
  final Set<String> seen;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Divider(height: 1, color: c.line),
          SsReveal(
            index: i,
            child: Builder(
              builder: (context) {
                final it = items[i];
                final novo = !seen.contains(it.id);
                final corpo = Padding(
                  padding: EdgeInsets.symmetric(vertical: d.rowPadV, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          if (it.date != null)
                            Text(
                              s.formatDayMonth(it.date!),
                              style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                            ),
                          if (novo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: c.accentSolid, borderRadius: BorderRadius.circular(99)),
                              child: Text(
                                s.whatsNewNew.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: AppType.micro,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: AppType.trackingCaps,
                                  color: AppColors.onDark,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        it.title,
                        style: TextStyle(fontSize: AppType.body, fontWeight: FontWeight.w700, color: c.ink),
                      ),
                      if (it.text != null)
                        Text(
                          it.text!,
                          style: TextStyle(fontSize: AppType.sub, height: AppType.leading, color: c.muted),
                        ),
                    ],
                  ),
                );
                if (it.onTap == null) return MergeSemantics(child: corpo);
                return InkWell(
                  borderRadius: BorderRadius.circular(d.radiusField),
                  onTap: () {
                    Navigator.of(context).pop();
                    it.onTap!();
                  },
                  child: corpo,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
