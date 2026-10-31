import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Situação de uma mensagem da pessoa no [SsChatBubble].
enum SsChatStatus { sending, sent, failed }

/// Bolha de conversa com a IA. Da pessoa ([fromMe]): cor da marca, à direita.
/// Da IA: superfície, à esquerda, com o ✦. Entra com mola. [text] aceita
/// **negrito**; para outra coisa (cartão, lista), passe [child].
class SsChatBubble extends StatelessWidget {
  const SsChatBubble({super.key, this.text, this.child, required this.fromMe, this.time, this.status})
    : assert(text != null || child != null);

  final String? text;
  final Widget? child;
  final bool fromMe;

  /// Já formatada ("14:32").
  final String? time;
  final SsChatStatus? status;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final fg = fromMe ? AppColors.onDark : c.ink;
    const r = Radius.circular(18);
    const cauda = Radius.circular(6);
    final bolha = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: fromMe ? c.accent : c.surface,
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: fromMe ? r : cauda,
          bottomRight: fromMe ? cauda : r,
        ),
        border: !fromMe && c.isDark ? Border.all(color: c.line) : null,
        boxShadow: !fromMe && !c.isDark ? AppShadows.card : null,
      ),
      child:
          child ??
          Text.rich(
            TextSpan(children: ssBoldSpans(text!)),
            style: TextStyle(color: fg, fontSize: AppType.body, height: 1.4),
          ),
    );

    final rodape = [
      if (time != null)
        Text(
          time!,
          style: TextStyle(color: c.muted, fontSize: AppType.label),
        ),
      if (status != null) ...[const SizedBox(width: 4), _Status(status!)],
    ];

    return _Entrada(
      alignment: fromMe ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!fromMe) ...[const SsAiMark(), const SizedBox(width: 8)],
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: math.min(MediaQuery.sizeOf(context).width * .78, 520)),
                    child: bolha,
                  ),
                ),
              ],
            ),
            if (rodape.isNotEmpty)
              Padding(
                // Com o ✦, o horário alinha com a bolha (28 + 8).
                padding: EdgeInsets.only(top: 3, left: fromMe ? 4 : 40, right: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: rodape),
              ),
          ],
        ),
      ),
    );
  }
}

/// Quebra `**negrito**` em spans (o resto vira texto simples).
List<TextSpan> ssBoldSpans(String s) {
  final partes = s.split('**');
  // Número par de partes = um ** sem par: não formata.
  if (partes.length.isEven) return [TextSpan(text: s)];
  return [
    for (var i = 0; i < partes.length; i++)
      if (partes[i].isNotEmpty)
        TextSpan(
          text: partes[i],
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w800) : null,
        ),
  ];
}

class _Status extends StatelessWidget {
  const _Status(this.s);
  final SsChatStatus s;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return switch (s) {
      SsChatStatus.sending => Icon(Icons.schedule_rounded, size: 13, color: c.muted, semanticLabel: 'Enviando'),
      SsChatStatus.sent => Icon(Icons.check_rounded, size: 14, color: c.muted, semanticLabel: 'Enviada'),
      SsChatStatus.failed => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
          const SizedBox(width: 3),
          Text(
            'Não enviada',
            style: TextStyle(color: c.dangerText, fontSize: AppType.label, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    };
  }
}

/// O ✦ da IA: círculo tonal da marca (28 px) ao lado das bolhas dela.
class SsAiMark extends StatelessWidget {
  const SsAiMark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
        child: Icon(Icons.auto_awesome_rounded, size: 15, color: c.accentText),
      ),
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada({required this.child, required this.alignment});
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: SsMotion.base,
      curve: SsMotion.spring,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: .85 + .15 * t, alignment: alignment, child: child),
      ),
      child: child,
    );
  }
}

/// A IA "pensando": três pontos que ondulam numa bolha (a única animação
/// contínua da suíte) e, opcional, um [text] ("Pensando…").
class SsThinking extends StatefulWidget {
  const SsThinking({super.key, this.text});

  final String? text;

  @override
  State<SsThinking> createState() => _SsThinkingState();
}

class _SsThinkingState extends State<SsThinking> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Semantics(
      liveRegion: true,
      label: widget.text ?? 'Pensando',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SsAiMark(),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(6),
                  ),
                  border: c.isDark ? Border.all(color: c.line) : null,
                  boxShadow: c.isDark ? null : AppShadows.card,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _c,
                      builder: (_, _) => Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            _ponto(c, (_c.value - i * .15) % 1),
                          ],
                        ],
                      ),
                    ),
                    if (widget.text != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        widget.text!,
                        style: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sobe e clareia na primeira metade do ciclo; descansa na segunda.
  Widget _ponto(SsColors c, double fase) {
    final onda = fase < .5 ? math.sin(fase * 2 * math.pi) : 0.0;
    return Transform.translate(
      offset: Offset(0, -4 * onda),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: Color.lerp(c.muted2, c.accent, onda), shape: BoxShape.circle),
      ),
    );
  }
}

/// Campo da conversa + botão de enviar redondo que acende quando há texto.
/// [onSend] recebe o texto sem espaços nas pontas; limpar o campo é do app
/// (para devolver o texto se o envio falhar). [sending] troca o ícone por
/// carregando e trava o envio.
class SsChatInput extends StatelessWidget {
  const SsChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.hint = 'Escreva uma mensagem',
    this.sending = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final String hint;
  final bool sending;

  void _enviar() {
    final t = controller.text.trim();
    if (t.isEmpty || sending) return;
    SsHaptics.tick();
    onSend(t);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: c.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final pode = controller.text.trim().isNotEmpty && !sending;
                return Semantics(
                  button: true,
                  enabled: pode,
                  label: 'Enviar',
                  child: ExcludeSemantics(
                    child: AnimatedScale(
                      scale: pode || reduceMotion(context) ? 1 : .9,
                      duration: SsMotion.fast,
                      curve: SsMotion.spring,
                      child: Material(
                        color: pode ? c.accent : c.field,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: pode ? _enviar : null,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: sending
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: c.muted),
                                    )
                                  : Icon(Icons.arrow_upward_rounded, color: pode ? AppColors.onDark : c.muted),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
