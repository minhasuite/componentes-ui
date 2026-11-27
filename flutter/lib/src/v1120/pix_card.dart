// v1.12.0 "Kit Brasil": o cartão do Pix (par do Ss::PixCardComponent). Só exibe: gerar a cobrança e saber que
// pagou é do app (o PSP dele); o cartão recebe o copia e cola, o estado e a validade.
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
import '../v1140/success_check.dart';
import 'br.dart';
import 'qr.dart';
import 'strings.dart';

/// Estado da cobrança Pix.
enum SsPixStatus {
  /// Esperando o pagamento (o QR e o copiar ficam à vista).
  waiting,

  /// Pagou (o QR dá lugar ao ✓ com a animação de sucesso).
  paid,

  /// Passou da validade (o QR apaga; com `onRegenerate`, o botão de gerar outro).
  expired,
}

/// O Pix de uma cobrança: o QR (gerado do [code] pelo [SsQrImage], ou o [qr] pronto do PSP), o valor, o
/// recebedor, a validade com contagem regressiva, o "Copiar código" com retorno e o estado.
///
/// ```dart
/// SsPixCard(code: cobranca.copiaECola, expiresAt: cobranca.expira, status: pago ? SsPixStatus.paid : SsPixStatus.waiting)
/// ```
///
/// Sem [amountCents] e [receiver], o cartão lê do próprio copia e cola (campos 54 e 59 do BR Code). Ao zerar a
/// contagem, o cartão passa a "expirado" sozinho e chama [onExpired] (o app atualiza o [status]).
class SsPixCard extends StatefulWidget {
  const SsPixCard({
    super.key,
    required this.code,
    this.amountCents,
    this.receiver,
    this.expiresAt,
    this.status = SsPixStatus.waiting,
    this.qr,
    this.title,
    this.hint,
    this.onCopy,
    this.onExpired,
    this.onRegenerate,
    this.now,
  });

  /// O Pix copia e cola (BR Code).
  final String code;
  final int? amountCents;
  final String? receiver;
  final DateTime? expiresAt;
  final SsPixStatus status;

  /// O QR pronto (a imagem que o PSP devolve). Sem ele, o pacote gera do [code].
  final Widget? qr;
  final String? title;

  /// A dica embaixo; `''` tira.
  final String? hint;

  /// Depois de copiar (o código já está na área de transferência).
  final VoidCallback? onCopy;
  final VoidCallback? onExpired;

  /// Mostra "Gerar outro código" no expirado.
  final VoidCallback? onRegenerate;

  /// O relógio (teste e catálogo); sem ele, `DateTime.now`.
  final DateTime Function()? now;

  @override
  State<SsPixCard> createState() => _SsPixCardState();
}

class _SsPixCardState extends State<SsPixCard> {
  Timer? _tick;
  Timer? _copiedTimer;
  var _copied = false;
  var _expiredLocal = false;

  DateTime _now() => (widget.now ?? DateTime.now)();

  Duration get _left {
    final e = widget.expiresAt;
    if (e == null) return Duration.zero;
    final l = e.difference(_now());
    return l.isNegative ? Duration.zero : l;
  }

  SsPixStatus get _status =>
      widget.status == SsPixStatus.waiting && _expiredLocal ? SsPixStatus.expired : widget.status;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(SsPixCard old) {
    super.didUpdateWidget(old);
    if (old.expiresAt != widget.expiresAt || old.status != widget.status) {
      _expiredLocal = false;
      _arm();
    }
    if (old.status != SsPixStatus.paid && widget.status == SsPixStatus.paid) SsHaptics.success();
  }

  void _arm() {
    _tick?.cancel();
    if (widget.expiresAt == null || widget.status != SsPixStatus.waiting) return;
    if (_left == Duration.zero) {
      _expiredLocal = true;
      return;
    }
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_left == Duration.zero) {
        _tick?.cancel();
        setState(() => _expiredLocal = true);
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    SsHaptics.selection();
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    widget.onCopy?.call();
  }

  static String clock(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final br = SsBrStrings.of(context);
    final f = SsFormats.of(context);
    final parsed = SsPixCode.parse(widget.code);
    final amount = widget.amountCents ?? parsed?.amountCents;
    final receiver = widget.receiver ?? parsed?.name;
    final st = _status;
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.medium;

    final (badgeLabel, badgeVariant) = switch (st) {
      SsPixStatus.waiting => (br.pixWaiting, SsBadgeVariant.warning),
      SsPixStatus.paid => (br.pixPaid, SsBadgeVariant.success),
      SsPixStatus.expired => (br.pixExpired, SsBadgeVariant.danger),
    };

    final qrBox = Container(
      constraints: const BoxConstraints(maxWidth: 232),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.onDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.line),
      ),
      child: AspectRatio(aspectRatio: 1, child: widget.qr ?? SsQrImage(data: widget.code, margin: 1)),
    );

    final Widget centro = switch (st) {
      SsPixStatus.paid => _Paid(key: const ValueKey('paid'), text: br.pixPaidHint),
      SsPixStatus.expired => Column(
        key: const ValueKey('expired'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: .25, child: ExcludeSemantics(child: qrBox)),
          const SizedBox(height: 12),
          Text(
            br.pixExpiredHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
          ),
          if (widget.onRegenerate != null) ...[
            const SizedBox(height: 12),
            SsButton(
              label: br.pixRegenerate,
              icon: Icons.refresh_rounded,
              expand: false,
              onPressed: widget.onRegenerate,
            ),
          ],
        ],
      ),
      SsPixStatus.waiting => Semantics(
        key: const ValueKey('waiting'),
        image: true,
        label: br.pixQr,
        child: ExcludeSemantics(child: qrBox),
      ),
    };

    final hint = widget.hint ?? br.pixHint;
    return SsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title ?? br.pixTitle,
                  style: TextStyle(color: c.ink, fontSize: d.font(AppType.set), fontWeight: FontWeight.w800),
                ),
              ),
              Semantics(liveRegion: true, child: SsBadge(badgeLabel, variant: badgeVariant, dot: true)),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: '${br.pixAmount}: ${amount == null ? br.pixAnyAmount : f.money(amount)}',
            excludeSemantics: true,
            child: Text(
              amount == null ? br.pixAnyAmount : f.money(amount),
              style: AppTheme.number(context, size: d.font(28), weight: FontWeight.w700, color: c.ink),
            ),
          ),
          if (receiver != null && receiver.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${br.pixReceiver}: $receiver',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: AnimatedSwitcher(duration: dur, switchInCurve: SsMotion.enter, child: centro),
          ),
          if (st == SsPixStatus.waiting && widget.expiresAt != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                SsBrStrings.fill(br.pixValidFor, {'time': clock(_left)}),
                style: AppTheme.number(context, size: d.font(AppType.sub), color: c.muted),
              ),
            ),
          ],
          if (st == SsPixStatus.waiting) ...[
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: d.padX - 2, vertical: 10),
              decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(d.radiusField)),
              child: Semantics(
                label: br.pixCode,
                value: widget.code,
                excludeSemantics: true,
                child: Text(
                  widget.code,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.number(context, size: AppType.meta, color: c.ink2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: SsButton(
                label: _copied ? br.pixCopied : br.pixCopy,
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                variant: _copied ? SsButtonVariant.success : SsButtonVariant.primary,
                onPressed: _copy,
              ),
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: d.font(AppType.meta)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// O ✓ do pago: o círculo cresce com a mola (sem movimento: já cheio).
class _Paid extends StatelessWidget {
  const _Paid({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final ok = SsTone.success.colors(context);
    final circulo = Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(color: ok.soft, shape: BoxShape.circle),
      // v1.14.0: o ✓ se desenha (a vibração já veio na troca de estado).
      child: Center(
        child: ExcludeSemantics(child: SsSuccessCheck(size: 64, color: ok.solid, haptic: false)),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        reduceMotion(context)
            ? circulo
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: .4, end: 1),
                duration: SsMotion.long,
                curve: SsMotion.spring,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: circulo,
              ),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.ink, fontSize: d.font(AppType.body), fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
