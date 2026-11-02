import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'illustrations.dart';
import 'motion.dart';
import 'ss_button.dart';
import 'ss_progress.dart';

/// Uma página do [SsOnboarding]: [illustration] (qualquer widget) ou, sem
/// ela, a [EmptyIllustration] com [icon]. [action] fica embaixo do texto
/// ("Permitir notificações", "Entrar com Google").
class SsOnboardingPage {
  const SsOnboardingPage({
    required this.title,
    required this.text,
    this.icon = Icons.auto_awesome_outlined,
    this.illustration,
    this.action,
  });

  final String title;
  final String text;
  final IconData icon;
  final Widget? illustration;
  final Widget? action;
}

/// Boas-vindas em páginas: desliza entre [pages], indicador em pílula que
/// estica na página atual, "Pular" no topo e botão que vira [doneLabel] na
/// última. [onDone] é chamado ao pular ou terminar (o app grava que já viu).
class SsOnboarding extends StatefulWidget {
  const SsOnboarding({
    super.key,
    required this.pages,
    required this.onDone,
    this.doneLabel = 'Começar',
    this.nextLabel = 'Continuar',
    this.skipLabel = 'Pular',
    this.initialPage = 0,
  });

  final List<SsOnboardingPage> pages;
  final VoidCallback onDone;
  final String doneLabel;
  final String nextLabel;
  final String skipLabel;
  final int initialPage;

  @override
  State<SsOnboarding> createState() => _SsOnboardingState();
}

class _SsOnboardingState extends State<SsOnboarding> {
  late final _pc = PageController(initialPage: widget.initialPage);
  late int _i = widget.initialPage;

  bool get _last => _i == widget.pages.length - 1;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_last) return widget.onDone();
    _pc.nextPage(
      duration: reduceMotion(context) ? const Duration(milliseconds: 1) : SsMotion.slow,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final reduce = reduceMotion(context);
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _last ? 0 : 1,
                duration: SsMotion.fast,
                child: _last
                    ? const SizedBox.shrink()
                    : TextButton(onPressed: widget.onDone, child: Text(widget.skipLabel)),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: widget.pages.length,
              onPageChanged: (v) {
                SsHaptics.tick();
                setState(() => _i = v);
              },
              itemBuilder: (_, i) {
                final p = widget.pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      p.illustration ?? EmptyIllustration(icon: p.icon, size: 168),
                      const SizedBox(height: 28),
                      Semantics(
                        header: true,
                        child: Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.ink, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        p.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.muted, fontSize: AppType.body, height: 1.45),
                      ),
                      if (p.action != null) ...[const SizedBox(height: 20), p.action!],
                    ],
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: 'Página ${_i + 1} de ${widget.pages.length}',
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.pages.length; i++)
                    AnimatedContainer(
                      duration: reduce ? Duration.zero : SsMotion.base,
                      curve: SsMotion.spring,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _i ? c.accent : c.muted2,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: SsButton(label: _last ? widget.doneLabel : widget.nextLabel, onPressed: _next),
          ),
        ],
      ),
    );
  }
}

/// Um passo do [SsChecklistCard]. [onTap] leva à tela que faz o passo.
class SsChecklistItem {
  const SsChecklistItem(this.label, {this.done = false, this.onTap});

  final String label;
  final bool done;
  final VoidCallback? onTap;
}

/// "Primeiros passos": barra de progresso e itens que ganham ✓ e são riscados
/// (com animação) quando [SsChecklistItem.done] vira verdadeiro. Quando o
/// último é feito, solta confete e oferece fechar ([onDismiss]).
class SsChecklistCard extends StatefulWidget {
  const SsChecklistCard({super.key, this.title = 'Primeiros passos', required this.items, this.onDismiss});

  final String title;
  final List<SsChecklistItem> items;
  final VoidCallback? onDismiss;

  @override
  State<SsChecklistCard> createState() => _SsChecklistCardState();
}

class _SsChecklistCardState extends State<SsChecklistCard> {
  static bool _all(List<SsChecklistItem> l) => l.isNotEmpty && l.every((e) => e.done);

  @override
  void didUpdateWidget(SsChecklistCard old) {
    super.didUpdateWidget(old);
    if (!_all(old.items) && _all(widget.items)) {
      SsHaptics.success();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSsConfetti(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final feitos = widget.items.where((e) => e.done).length;
    final total = widget.items.length;
    final pronto = _all(widget.items);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: c.isDark ? Border.all(color: c.line) : null,
        boxShadow: c.isDark ? null : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(color: c.ink, fontSize: AppType.md, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$feitos de $total',
                style: AppTheme.number(context, size: AppType.sub, color: pronto ? c.successText : c.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SsProgress(total == 0 ? 0 : feitos / total, height: 6),
          const SizedBox(height: 6),
          for (final it in widget.items) _Passo(it),
          AnimatedSize(
            duration: reduceMotion(context) ? Duration.zero : SsMotion.base,
            curve: Curves.easeOutCubic,
            child: pronto
                ? Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.celebration_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tudo pronto!',
                              style: TextStyle(color: c.successText, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (widget.onDismiss != null)
                            TextButton(onPressed: widget.onDismiss, child: const Text('Fechar')),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo(this.it);
  final SsChecklistItem it;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = reduceMotion(context) ? Duration.zero : SsMotion.base;
    return Semantics(
      button: it.onTap != null,
      checked: it.done,
      child: InkWell(
        onTap: it.onTap,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              AnimatedContainer(
                duration: d,
                curve: SsMotion.spring,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: it.done ? AppColors.success : Colors.transparent,
                  border: Border.all(color: it.done ? AppColors.success : c.muted2, width: 2),
                ),
                child: AnimatedScale(
                  scale: it.done ? 1 : 0,
                  duration: d,
                  curve: SsMotion.spring,
                  child: const Icon(Icons.check_rounded, size: 14, color: AppColors.onDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: it.done ? 1 : 0),
                    duration: d,
                    curve: Curves.easeOutCubic,
                    builder: (_, t, _) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color.lerp(c.ink, c.muted, t),
                            fontSize: AppType.set,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // O risco corre da esquerda para a direita.
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: t,
                              child: Container(height: 1.5, color: c.muted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!it.done && it.onTap != null) Icon(Icons.chevron_right_rounded, color: c.muted2),
            ],
          ),
        ),
      ),
    );
  }
}
