// v1.13.0 "confiança na IA e suíte": continuar no outro aparelho (par do Ss::ContinueOnComponent). No app, "Continuar
// no computador" mostra o link profundo da tela atual (com o estado que o app serializa: filtros, rascunho) e o QR
// (SsQrImage da v1.12). O web faz o "Continuar no celular" com o mesmo link e o mesmo estado (ComponentesUi::Handoff).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_button.dart';
import '../ss_sheet.dart';
import '../v1120/qr.dart';
import 'strings.dart';

/// O estado da tela no link: JSON compacto em base64url sem "=" (o mesmo `ComponentesUi::Handoff` da gem; o vetor
/// de `docs/v1130/handoff.json` passa nos dois).
abstract final class SsHandoff {
  static String encode(Map<String, Object?> state) =>
      base64Url.encode(utf8.encode(jsonEncode(state))).replaceAll('=', '');

  /// O estado de volta, ou nulo se o texto não é um estado válido.
  static Map<String, Object?>? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final pad = '=' * ((4 - text.length % 4) % 4);
      final v = jsonDecode(utf8.decode(base64Url.decode('$text$pad')));
      return v is Map<String, Object?> ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// [base] com o estado no parâmetro [param] ("?s=…" ou "&s=…"). Sem estado, o próprio [base].
  static String link(String base, Map<String, Object?>? state, {String param = 's'}) {
    if (state == null || state.isEmpty) return base;
    return '$base${base.contains('?') ? '&' : '?'}$param=${encode(state)}';
  }
}

/// Para onde a pessoa vai continuar.
enum SsContinueTarget {
  /// "Continuar no celular" (no web; o QR é o caminho).
  phone,

  /// "Continuar no computador" (no app; o link é o caminho, o QR serve a outro celular ou tablet).
  computer,
}

/// O cartão de continuar: o QR do [url], a dica, o link com "Copiar link" e, com [onShare], "Compartilhar" (a folha
/// do sistema é do app). O [url] é o link profundo que o app monta, de preferência com [SsHandoff.link].
///
/// `SsContinueOn(url: SsHandoff.link('https://vendas.minhasuite.com/pedidos', {'filtros': f, 'rascunho': r}))`
class SsContinueOn extends StatefulWidget {
  const SsContinueOn({
    super.key,
    required this.url,
    this.target = SsContinueTarget.computer,
    this.hint,
    this.onCopy,
    this.onShare,
    this.qrSize = 200,
  });

  final String url;
  final SsContinueTarget target;
  final String? hint;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final double qrSize;

  /// Acima disso o QR fica denso; o cartão avisa para usar o link.
  static const longUrl = 300;

  @override
  State<SsContinueOn> createState() => _SsContinueOnState();
}

class _SsContinueOnState extends State<SsContinueOn> {
  var _copied = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    SsHaptics.selection();
    if (!mounted) return;
    setState(() => _copied = true);
    _t?.cancel();
    _t = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    widget.onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final phone = widget.target == SsContinueTarget.phone;
    final hint = widget.hint ?? (phone ? t.continuePhoneHint : t.continueComputerHint);
    final qr = Center(
      child: Container(
        padding: EdgeInsets.all(d.space(12)),
        decoration: BoxDecoration(
          color: AppColors.onDark,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: c.line),
        ),
        child: SsQrImage(data: widget.url, size: widget.qrSize, margin: 1, semanticLabel: t.continueQr),
      ),
    );
    final link = Container(
      padding: EdgeInsets.symmetric(horizontal: d.space(12), vertical: d.space(10)),
      decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Semantics(
        label: '${t.continueLink}: ${widget.url}',
        excludeSemantics: true,
        child: SelectableText(
          widget.url,
          maxLines: 3,
          style: AppTheme.number(context, size: AppType.meta, color: c.ink),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hint,
          style: TextStyle(fontSize: AppType.sub, color: c.ink2, height: AppType.leading),
        ),
        SizedBox(height: d.space(16)),
        if (phone) ...[qr, SizedBox(height: d.space(16)), link] else ...[link, SizedBox(height: d.space(16)), qr],
        if (widget.url.length > SsContinueOn.longUrl) ...[
          SizedBox(height: d.space(8)),
          Text(
            t.continueLong,
            style: TextStyle(fontSize: AppType.meta, color: c.aquecText),
          ),
        ],
        SizedBox(height: d.space(12)),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: d.space(8),
          runSpacing: d.space(8),
          children: [
            if (widget.onShare != null)
              SsButton.ghost(
                label: t.continueShare,
                icon: Icons.ios_share_rounded,
                expand: false,
                onPressed: widget.onShare,
              ),
            Semantics(
              liveRegion: true,
              child: SsButton(
                label: _copied ? t.continueCopied : t.continueCopy,
                icon: _copied ? Icons.check_rounded : Icons.link_rounded,
                expand: false,
                onPressed: _copy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Abre o [SsContinueOn] numa folha ("Continuar no computador").
Future<void> showSsContinueOn(
  BuildContext context, {
  required String url,
  SsContinueTarget target = SsContinueTarget.computer,
  VoidCallback? onShare,
}) {
  final t = SsTrustStrings.of(context);
  return showSsSheet<void>(
    context,
    title: target == SsContinueTarget.phone ? t.continuePhone : t.continueComputer,
    icon: target == SsContinueTarget.phone ? Icons.smartphone_rounded : Icons.computer_rounded,
    child: SsContinueOn(url: url, target: target, onShare: onShare),
  );
}
