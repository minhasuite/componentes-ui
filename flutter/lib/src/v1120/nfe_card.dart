// v1.12.0 "Kit Brasil": o cartão da nota fiscal (par do Ss::NfeCardComponent): chave de acesso em blocos com
// copiar e a conferência do DV, emitente, CNPJ, data, valor, situação e o QR da consulta. Só exibe: a nota vem
// do app (o XML, a consulta à Sefaz).
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_badge.dart';
import '../ss_button.dart';
import '../ss_card.dart';
import '../ss_strings.dart';
import '../v14/pecas.dart' show SsNote;
import 'br.dart';
import 'qr.dart';
import 'strings.dart';

/// Situação da nota.
enum SsNfeStatus {
  authorized,
  canceled,
  denied,
  pending;

  SsBadgeVariant get variant => switch (this) {
    authorized => SsBadgeVariant.success,
    canceled => SsBadgeVariant.danger,
    denied => SsBadgeVariant.danger,
    pending => SsBadgeVariant.warning,
  };
}

/// A nota fiscal num cartão. Da [accessKey] (44 dígitos) saem o modelo, o número, a série, a UF e o CNPJ do
/// emitente quando o app não passa; o DV é conferido (errado: aviso no cartão). Com [qrUrl] (a URL do QR da
/// NFC-e/consulta), o QR fica ao lado da chave e [onOpen] mostra "Consultar na Sefaz".
class SsNfeCard extends StatefulWidget {
  const SsNfeCard({
    super.key,
    required this.accessKey,
    this.issuer,
    this.issuerCnpj,
    this.issuedAt,
    this.amountCents,
    this.status,
    this.qrUrl,
    this.onOpen,
    this.onCopy,
    this.onTap,
  });

  final String accessKey;

  /// Razão social do emitente.
  final String? issuer;

  /// Sem ele, o da chave.
  final String? issuerCnpj;
  final DateTime? issuedAt;
  final int? amountCents;
  final SsNfeStatus? status;
  final String? qrUrl;
  final VoidCallback? onOpen;
  final VoidCallback? onCopy;
  final VoidCallback? onTap;

  @override
  State<SsNfeCard> createState() => _SsNfeCardState();
}

class _SsNfeCardState extends State<SsNfeCard> {
  var _copied = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: SsBr.digits(widget.accessKey)));
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
    final br = SsBrStrings.of(context);
    final s = SsStrings.of(context);
    final f = SsFormats.of(context);
    final k = SsNfeKey.parse(widget.accessKey);
    final title = k?.modelName ?? br.nfeTitle;
    final number = k == null
        ? null
        : SsBrStrings.fill(br.nfeNumber, {'number': f.integer(k.number), 'series': '${k.series}'});
    final cnpj = widget.issuerCnpj ?? k?.cnpj;

    Widget linha(String rotulo, String valor, {bool mono = false}) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              rotulo,
              style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: mono
                  ? AppTheme.number(context, size: d.font(AppType.sub), color: c.ink)
                  : TextStyle(color: c.ink, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    final chave = Semantics(
      label: br.nfeKey,
      value: SsBr.digits(widget.accessKey),
      excludeSemantics: true,
      child: Text(
        SsBr.formatNfeKey(widget.accessKey),
        style: AppTheme.number(context, size: d.font(AppType.sub), color: c.ink).copyWith(height: 1.5),
      ),
    );

    final qr = widget.qrUrl == null
        ? null
        : Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.onDark,
              borderRadius: BorderRadius.circular(AppRadius.thumb),
              border: Border.all(color: c.line),
            ),
            child: SsQrImage(data: widget.qrUrl!, margin: 0, semanticLabel: br.nfeQr),
          );

    return SsCard(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: c.ink, fontSize: d.font(AppType.set), fontWeight: FontWeight.w800),
                    ),
                    if (number != null)
                      Text(
                        number,
                        style: TextStyle(color: c.muted, fontSize: d.font(AppType.meta)),
                      ),
                  ],
                ),
              ),
              if (widget.status != null)
                SsBadge(br.nfeStatus[widget.status!.name]!, variant: widget.status!.variant, dot: true),
            ],
          ),
          if (widget.issuer != null) linha(br.nfeIssuer, widget.issuer!),
          if (cnpj != null && cnpj.isNotEmpty) linha(br.nfeCnpj, SsBr.formatCnpj(cnpj), mono: true),
          if (widget.issuedAt != null) linha(br.nfeDate, s.formatDate(widget.issuedAt!), mono: true),
          if (widget.amountCents != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      br.nfeAmount,
                      style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
                    ),
                  ),
                  Text(
                    f.money(widget.amountCents),
                    style: AppTheme.number(context, size: d.font(AppType.lg), weight: FontWeight.w700, color: c.ink),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(d.padX - 4),
            decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(d.radiusField)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        br.nfeKey.toUpperCase(),
                        style: TextStyle(
                          color: c.muted,
                          fontSize: AppType.label,
                          fontWeight: FontWeight.w800,
                          letterSpacing: AppType.trackingCaps,
                        ),
                      ),
                      const SizedBox(height: 4),
                      chave,
                    ],
                  ),
                ),
                if (qr != null) ...[const SizedBox(width: 12), qr],
              ],
            ),
          ),
          if (k == null || !k.valid) ...[
            const SizedBox(height: 8),
            SsNote(br.nfeKeyInvalid, icon: Icons.warning_amber_rounded, tone: SsTone.warning),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Semantics(
                liveRegion: true,
                child: SsButton.ghost(
                  label: _copied ? br.nfeKeyCopied : br.nfeCopyKey,
                  icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                  tone: _copied ? SsTone.success : null,
                  small: true,
                  expand: false,
                  onPressed: _copy,
                ),
              ),
              if (widget.onOpen != null)
                SsButton.ghost(
                  label: br.nfeOpen,
                  icon: Icons.open_in_new_rounded,
                  small: true,
                  expand: false,
                  onPressed: widget.onOpen,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
