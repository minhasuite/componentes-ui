// v1.9 · paridade_app: histórico de alterações (par do Ss::AuditTrailComponent).
import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../motion.dart';
import '../../ss_badge.dart' show SsTone;
import '../../ss_list.dart' show SsAvatar;
import '../../ss_strings.dart';

/// Um campo que mudou: de [from] para [to] (nulo ou vazio = "vazio").
class SsAuditChange {
  const SsAuditChange(this.field, {this.from, this.to});

  final String field;
  final String? from;
  final String? to;
}

/// Uma linha do [SsAuditTrail]: quem, quando, o quê, os campos e uma nota.
class SsAuditEntry {
  const SsAuditEntry({required this.who, required this.action, this.at, this.changes = const [], this.note});

  final String who;

  /// "alterou o pedido 1042".
  final String action;
  final DateTime? at;
  final List<SsAuditChange> changes;
  final String? note;
}

/// Histórico de mudanças: avatar ([SsAvatar]) ligado por um fio, "**Ana
/// Souza** alterou o pedido 1042 · 02/11 14:30" e cada campo "de → para" com
/// só o trecho que mudou destacado (riscado no de, verde no para). Entra em
/// cascata ([SsReveal]). Par do `Ss::AuditTrailComponent` (mesma conta de
/// diferença por palavra: [diff]).
class SsAuditTrail extends StatelessWidget {
  const SsAuditTrail({super.key, required this.entries, this.label});

  final List<SsAuditEntry> entries;

  /// Padrão: [SsStrings.auditTrailLabel].
  final String? label;

  /// Divide de/para em (prefixo comum, trecho diferente, sufixo comum), por
  /// palavra, como o `diff` do web.
  static ((String, String, String), (String, String, String)) diff(String? from, String? to) {
    final sep = RegExp(r'(\s+)');
    List<String> parte(String s) {
      final out = <String>[];
      var i = 0;
      for (final m in sep.allMatches(s)) {
        if (m.start > i) out.add(s.substring(i, m.start));
        out.add(m[0]!);
        i = m.end;
      }
      if (i < s.length) out.add(s.substring(i));
      return out;
    }

    final a = parte(from ?? ''), b = parte(to ?? '');
    var pre = 0;
    while (pre < a.length && pre < b.length && a[pre] == b[pre]) {
      pre++;
    }
    var suf = 0;
    while (suf < a.length - pre && suf < b.length - pre && a[a.length - 1 - suf] == b[b.length - 1 - suf]) {
      suf++;
    }
    (String, String, String) corta(List<String> x) =>
        (x.sublist(0, pre).join(), x.sublist(pre, x.length - suf).join(), x.sublist(x.length - suf).join());
    return (corta(a), corta(b));
  }

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    return Semantics(
      container: true,
      label: label ?? s.auditTrailLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < entries.length; i++)
            SsReveal(
              index: i,
              child: _Linha(entries[i], last: i == entries.length - 1),
            ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.e, {required this.last});
  final SsAuditEntry e;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final at = e.at;
    String two(int n) => n.toString().padLeft(2, '0');
    final quando = at == null ? null : '${s.formatDayMonth(at)} ${two(at.hour)}:${two(at.minute)}';
    final verde = SsTone.success.colors(context);
    final estreito = MediaQuery.sizeOf(context).width / MediaQuery.textScalerOf(context).scale(1) < 380;

    Widget mudanca(SsAuditChange m) {
      final ((fa0, fa1, fa2), (fb0, fb1, fb2)) = SsAuditTrail.diff(m.from, m.to);
      final base = TextStyle(fontSize: AppType.sub, height: AppType.leading, color: c.ink2);
      TextSpan vazio() => TextSpan(
        text: s.auditTrailEmpty,
        style: base.copyWith(fontStyle: FontStyle.italic, color: c.muted),
      );
      final de = (m.from ?? '').trim().isEmpty
          ? vazio()
          : TextSpan(
              style: base.copyWith(color: c.muted),
              children: [
                TextSpan(text: fa0),
                TextSpan(
                  text: fa1,
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: c.danger.withValues(alpha: .6),
                    decorationThickness: 2,
                  ),
                ),
                TextSpan(text: fa2),
              ],
            );
      final para = (m.to ?? '').trim().isEmpty
          ? vazio()
          : TextSpan(
              style: base.copyWith(color: c.ink),
              children: [
                TextSpan(text: fb0),
                TextSpan(
                  text: fb1,
                  style: TextStyle(backgroundColor: verde.soft, color: verde.text, fontWeight: FontWeight.w700),
                ),
                TextSpan(text: fb2),
              ],
            );
      final valor = Text.rich(
        TextSpan(
          children: [
            de,
            TextSpan(
              text: '  →  ',
              style: base.copyWith(color: c.muted),
            ),
            para,
          ],
        ),
      );
      final campo = Text(
        m.field,
        style: TextStyle(fontSize: AppType.sub, fontWeight: FontWeight.w600, color: c.muted),
      );
      return Semantics(
        container: true,
        label:
            '${m.field}: ${(m.from ?? '').trim().isEmpty ? s.auditTrailEmpty : m.from} '
            '${s.auditTrailTo} ${(m.to ?? '').trim().isEmpty ? s.auditTrailEmpty : m.to}',
        excludeSemantics: true,
        // Tela estreita (ou texto grande): o nome do campo em cima do valor.
        // (Sem LayoutBuilder: a linha usa IntrinsicHeight para o fio.)
        child: estreito
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [campo, valor])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 96, child: campo),
                  const SizedBox(width: 10),
                  Expanded(child: valor),
                ],
              ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                ExcludeSemantics(child: SsAvatar(e.who, size: 32)),
                if (!last)
                  Expanded(
                    child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: c.line),
                  ),
              ],
            ),
          ),
          SizedBox(width: d.gap),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: last ? 0 : d.gap * 1.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: AppType.set, height: AppType.leading, color: c.ink2),
                      children: [
                        TextSpan(
                          text: e.who,
                          style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                        ),
                        TextSpan(text: ' ${e.action}'),
                        if (quando != null)
                          TextSpan(
                            text: '  $quando',
                            style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                  if (e.changes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 6,
                        children: [for (final m in e.changes) mudanca(m)],
                      ),
                    ),
                  ],
                  if (e.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      e.note!,
                      style: TextStyle(fontSize: AppType.sub, color: c.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
