// v0.10 (casa): aviso com ações, microfone com nível e tela de bloqueio.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_badge.dart';
import '../ss_button.dart';
import '../ss_strings.dart';

/// Tom do [SsNoticeCard].
enum SsNoticeTone { info, warn, critical, success }

/// Uma ação do [SsNoticeCard]. A primeira da lista é a principal.
class SsNoticeAction {
  const SsNoticeAction(this.label, this.onPressed, {this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
}

/// Aviso com ações: ícone, título, texto, tom, hora e N botões (o primeiro
/// cheio, os outros fantasma) e o "dispensar" opcional. [onTap] torna o
/// cartão tocável; [image] mostra a foto embaixo do texto; [unread] marca o
/// aviso não lido (ponto e borda forte); [footer] é o rodapé ("Respondido:
/// Sim").
///
/// `SsNoticeCard(title: 'Porta aberta', text: 'Há 10 min', tone: SsNoticeTone.warn,
///   actions: [SsNoticeAction('Fechar', fechar), SsNoticeAction('Ignorar', ignorar)], onDismiss: dispensar)`
class SsNoticeCard extends StatelessWidget {
  const SsNoticeCard({
    super.key,
    required this.title,
    this.text,
    this.tone = SsNoticeTone.info,
    this.icon,
    this.time,
    this.actions = const [],
    this.onDismiss,
    this.dismissLabel,
    this.onTap,
    this.image,
    this.unread = false,
    this.footer,
  });

  final String title;
  final String? text;
  final SsNoticeTone tone;

  /// Padrão: um por tom (informação, alerta, erro, ok).
  final IconData? icon;

  /// Hora já formatada ("14:32", "há 5 min").
  final String? time;
  final List<SsNoticeAction> actions;
  final VoidCallback? onDismiss;

  /// Padrão: o do [SsStrings] do idioma.
  final String? dismissLabel;

  /// Toque no cartão (abrir o aviso, ir para a câmera). As ações e o ✕
  /// continuam com o próprio toque.
  final VoidCallback? onTap;

  /// Imagem embaixo do texto, na largura do cartão (16:9, cantos
  /// arredondados): instantâneo da câmera, foto do aviso. Ex.:
  /// `SsNetImage.bytes(...)` ou `Image(image: provider)`.
  final Widget? image;

  /// Não lido / ativo: ponto na cor do tom antes do título e borda mais
  /// forte e mais grossa.
  final bool unread;

  /// Rodapé abaixo de tudo, com um fio em cima: "Respondido: Sim", quem
  /// confirmou e quando. Texto solto ganha o estilo apagado e pequeno.
  final Widget? footer;

  SsTone get _tone => switch (tone) {
    SsNoticeTone.info => SsTone.info,
    SsNoticeTone.warn => SsTone.warning,
    SsNoticeTone.critical => SsTone.danger,
    SsNoticeTone.success => SsTone.success,
  };

  IconData get _icon =>
      icon ??
      switch (tone) {
        SsNoticeTone.info => Icons.info_outline_rounded,
        SsNoticeTone.warn => Icons.warning_amber_rounded,
        SsNoticeTone.critical => Icons.error_outline_rounded,
        SsNoticeTone.success => Icons.check_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final t = _tone.colors(context);
    final raio = BorderRadius.circular(AppRadius.card);
    Widget corpo = Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: t.text, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unread)
                      Padding(
                        padding: const EdgeInsets.only(top: 7, right: 7),
                        child: Semantics(
                          label: SsStrings.of(context).unread,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: t.solid, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          title,
                          style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: AppType.body),
                        ),
                      ),
                    ),
                    if (time != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 3),
                        child: Text(
                          time!,
                          style: AppTheme.number(context, size: AppType.label, color: c.muted),
                        ),
                      ),
                  ],
                ),
                if (text != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      text!,
                      style: TextStyle(color: c.ink2, fontSize: AppType.sub, height: 1.35),
                    ),
                  ),
                if (image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, right: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.thumb),
                      child: AspectRatio(aspectRatio: 16 / 9, child: image),
                    ),
                  ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, right: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (i, a) in actions.indexed)
                          SsButton(
                            label: a.label,
                            icon: a.icon,
                            onPressed: a.onPressed,
                            small: true,
                            expand: false,
                            variant: i == 0 ? SsButtonVariant.primary : SsButtonVariant.ghost,
                          ),
                      ],
                    ),
                  ),
                if (footer != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12, right: 6),
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: t.solid.withValues(alpha: c.isDark ? .22 : .16)),
                      ),
                    ),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                      child: IconTheme.merge(
                        data: IconThemeData(color: c.muted, size: 16),
                        child: footer!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              tooltip: dismissLabel ?? SsStrings.of(context).dismiss,
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 20, color: c.muted),
            )
          else
            const SizedBox(width: 6),
        ],
      ),
    );
    if (onTap != null) corpo = InkWell(onTap: onTap, borderRadius: raio, child: corpo);
    return Semantics(
      container: true,
      liveRegion: tone == SsNoticeTone.critical,
      button: onTap != null,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              t.solid.withValues(alpha: c.isDark ? (unread ? .11 : .07) : (unread ? .08 : .05)),
              c.surface,
            ),
            borderRadius: raio,
            // Não lido: a borda na cor do tom, mais forte e mais grossa.
            border: Border.all(
              color: t.solid.withValues(alpha: unread ? (c.isDark ? .75 : .62) : (c.isDark ? .35 : .28)),
              width: unread ? 1.6 : 1,
            ),
          ),
          child: corpo,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── microfone

/// Situação do [SsMicButton].
enum SsMicState { idle, listening, processing, error }

/// Botão redondo de microfone. Ouvindo, os anéis em volta crescem com o
/// [level] (0..1) que o app manda do áudio, como um medidor. Processando,
/// um arco gira em volta; com erro, fica vermelho.
class SsMicButton extends StatefulWidget {
  const SsMicButton({
    super.key,
    this.state = SsMicState.idle,
    this.level = 0,
    this.onPressed,
    this.size = 72,
    this.idleLabel,
    this.listeningLabel,
    this.processingLabel,
    this.errorLabel,
  });

  final SsMicState state;

  /// Nível do áudio, 0..1 (só em `listening`).
  final double level;
  final VoidCallback? onPressed;

  /// Diâmetro do botão; os anéis usam até 1,8× em volta.
  final double size;
  final String? idleLabel;
  final String? listeningLabel;
  final String? processingLabel;
  final String? errorLabel;

  @override
  State<SsMicButton> createState() => _SsMicButtonState();
}

class _SsMicButtonState extends State<SsMicButton> with SingleTickerProviderStateMixin {
  SsStrings get _s => SsStrings.of(context);
  late final _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  void _sync() {
    final girar = widget.state == SsMicState.processing && !reduceMotion(context);
    if (girar && !_spin.isAnimating) _spin.repeat();
    if (!girar && _spin.isAnimating) _spin.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SsMicButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = widget.state;
    final erro = s == SsMicState.error;
    final cor = erro ? AppColors.danger : c.accent;
    final rm = reduceMotion(context);
    final total = widget.size * 1.8;
    final label = switch (s) {
      SsMicState.idle => widget.idleLabel ?? _s.micIdle,
      SsMicState.listening => widget.listeningLabel ?? _s.micListening,
      SsMicState.processing => widget.processingLabel ?? _s.micProcessing,
      SsMicState.error => widget.errorLabel ?? _s.micError,
    };
    final nivel = s == SsMicState.listening ? widget.level.clamp(0.0, 1.0) : 0.0;

    return Semantics(
      button: true,
      label: label,
      enabled: widget.onPressed != null,
      child: SizedBox.square(
        dimension: total,
        child: TweenAnimationBuilder<double>(
          // O nível chega aos saltos (a cada ~50 ms): suaviza para os anéis não tremerem.
          tween: Tween(end: nivel),
          duration: rm ? Duration.zero : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          builder: (context, lv, child) => AnimatedBuilder(
            animation: _spin,
            builder: (context, child) => CustomPaint(
              painter: _MicPainter(
                level: lv,
                color: cor,
                listening: s == SsMicState.listening,
                processing: s == SsMicState.processing,
                spin: rm ? .1 : _spin.value,
                inner: widget.size / 2,
              ),
              child: child,
            ),
            child: child,
          ),
          child: Center(
            child: SsPressable(
              enabled: widget.onPressed != null,
              onTap: widget.onPressed,
              child: AnimatedContainer(
                duration: rm ? Duration.zero : SsMotion.base,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s == SsMicState.idle ? c.surface : cor,
                  border: s == SsMicState.idle ? Border.all(color: c.line, width: 1.5) : null,
                  boxShadow: s == SsMicState.idle ? AppShadows.card : c.tintedShadow(cor),
                ),
                child: Icon(
                  erro ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: widget.size * .42,
                  color: s == SsMicState.idle ? c.accentText : AppColors.onDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicPainter extends CustomPainter {
  _MicPainter({
    required this.level,
    required this.color,
    required this.listening,
    required this.processing,
    required this.spin,
    required this.inner,
  });
  final double level;
  final Color color;
  final bool listening;
  final bool processing;
  final double spin;
  final double inner;

  @override
  void paint(Canvas canvas, Size size) {
    final o = size.center(Offset.zero);
    final max = size.width / 2;
    if (listening) {
      // Três anéis: o de dentro reage primeiro; os de fora só com voz mais alta.
      for (var i = 0; i < 3; i++) {
        final parte = ((level - i * .22) / (1 - i * .22)).clamp(0.0, 1.0);
        final r = inner + 4 + (max - inner - 4) * (.25 + .75 * parte) * (i + 1) / 3;
        canvas.drawCircle(o, r, Paint()..color = color.withValues(alpha: .10 + .16 * parte * (1 - i * .25)));
      }
    }
    if (processing) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawCircle(
        o,
        inner + 7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color.withValues(alpha: .15),
      );
      canvas.drawArc(Rect.fromCircle(center: o, radius: inner + 7), spin * 2 * math.pi, 1.6, false, p);
    }
  }

  @override
  bool shouldRepaint(_MicPainter old) =>
      old.level != level ||
      old.spin != spin ||
      old.color != color ||
      old.listening != listening ||
      old.processing != processing;
}

// ──────────────────────────────────────────────────────── tela de bloqueio

/// Tela de bloqueio do app (só app): fundo com a marca desfocada, ícone do app,
/// mensagem e o botão "Desbloquear" (o app chama a biometria em [onUnlock]).
/// Com [pinFallback], um "Usar PIN" troca o botão pelo widget do PIN do app.
class SsLockScreen extends StatefulWidget {
  const SsLockScreen({
    super.key,
    this.appIcon,
    this.title,
    this.message,
    this.unlockLabel,
    this.onUnlock,
    this.pinFallback,
    this.pinLabel,
    this.backLabel,
    this.error,
    this.busy = false,
    this.showPin = false,
  });

  /// Ícone do app (o app passa o dele); padrão: cadeado.
  final Widget? appIcon;
  final String? title;
  final String? message;
  final String? unlockLabel;
  final VoidCallback? onUnlock;

  /// Teclado/campo de PIN do app.
  final Widget? pinFallback;
  final String? pinLabel;
  final String? backLabel;

  /// Mensagem de erro (biometria recusada, PIN errado).
  final String? error;

  /// Esperando a biometria: o botão mostra o carregando.
  final bool busy;

  /// Já começa no PIN.
  final bool showPin;

  @override
  State<SsLockScreen> createState() => _SsLockScreenState();
}

class _SsLockScreenState extends State<SsLockScreen> {
  SsStrings get _s => SsStrings.of(context);
  late bool _pin = widget.showPin && widget.pinFallback != null;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final rm = reduceMotion(context);
    final cores = c.brand.gradient.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fundo: o gradiente da marca com manchas desfocadas e um véu escuro por cima.
        DecoratedBox(decoration: BoxDecoration(gradient: c.gradient4)),
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50, tileMode: TileMode.decal),
          child: CustomPaint(painter: _ManchasPainter(cores)),
        ),
        ColoredBox(color: (c.isDark ? AppColors.pageOled : AppColors.inkLight).withValues(alpha: c.isDark ? .45 : .25)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.onDark.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.onDark.withValues(alpha: .28)),
                    ),
                    alignment: Alignment.center,
                    child: widget.appIcon ?? const Icon(Icons.lock_rounded, size: 40, color: AppColors.onDark),
                  ),
                  if (widget.title != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      widget.title!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.onDark,
                        fontWeight: FontWeight.w800,
                        fontSize: AppType.headerTitle,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    widget.message ?? _s.lockMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.onDarkSoft, fontSize: AppType.body),
                  ),
                  if (widget.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            widget.error!,
                            style: const TextStyle(
                              color: AppColors.onDark,
                              fontWeight: FontWeight.w700,
                              fontSize: AppType.meta,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: rm ? Duration.zero : SsMotion.slow,
                    switchInCurve: SsMotion.bounce,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(a), child: child),
                    ),
                    child: _pin
                        ? KeyedSubtree(key: const ValueKey('pin'), child: widget.pinFallback!)
                        : SizedBox(
                            key: const ValueKey('bio'),
                            width: 260,
                            child: SsPressable(
                              enabled: widget.onUnlock != null && !widget.busy,
                              child: FilledButton.icon(
                                onPressed: widget.busy ? null : widget.onUnlock,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.onDark,
                                  foregroundColor: c.brand.accentLight,
                                  disabledBackgroundColor: AppColors.onDark.withValues(alpha: .7),
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                                  textStyle: Theme.of(
                                    context,
                                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: AppType.body),
                                ),
                                icon: widget.busy
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2.4, color: c.brand.accentLight),
                                      )
                                    : const Icon(Icons.fingerprint_rounded),
                                label: Text(widget.unlockLabel ?? _s.unlock),
                              ),
                            ),
                          ),
                  ),
                  if (widget.pinFallback != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _pin = !_pin),
                      style: TextButton.styleFrom(foregroundColor: AppColors.onDark),
                      child: Text(_pin ? widget.backLabel ?? _s.useBiometrics : widget.pinLabel ?? _s.usePin),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManchasPainter extends CustomPainter {
  _ManchasPainter(this.cores);
  final List<Color> cores;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pts = [Offset(w * .15, h * .2), Offset(w * .85, h * .35), Offset(w * .3, h * .8), Offset(w * .8, h * .9)];
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(pts[i], w * .45, Paint()..color = cores[(i + 1) % cores.length].withValues(alpha: .85));
    }
  }

  @override
  bool shouldRepaint(_ManchasPainter old) => old.cores != cores;
}
