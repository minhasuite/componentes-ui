// v1.9 · paridade_app: depoimento, pessoa e mosaico (pares do Ss::ReviewCardComponent,
// Ss::PersonCardComponent e Ss::BentoGridComponent).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../motion.dart';
import '../../ss_badge.dart' show SsTone;
import '../../ss_card.dart';
import '../../ss_list.dart' show SsAvatar, SsAvatarStack;
import '../../ss_strings.dart';
import '../../v15/privacy.dart' show SsPrivate;
import '../../v16/rating.dart';

// ---------------------------------------------------------------------------
// Depoimento
// ---------------------------------------------------------------------------

/// Depoimento: estrelas ([SsRating], aceita meia), o texto, o avatar
/// ([SsAvatar]) com nome e "papel · data". As aspas grandes ficam no canto,
/// na cor suave da marca. Par do `Ss::ReviewCardComponent`.
///
/// `SsReviewCard(name: 'Carla Mendes', role: 'Padaria Central', rating: 4.5, text: '…', date: 'out/2026')`
class SsReviewCard extends StatelessWidget {
  const SsReviewCard({
    super.key,
    required this.name,
    required this.text,
    this.rating = 5,
    this.role,
    this.date,
    this.onTap,
  });

  final String name;
  final String text;
  final double rating;
  final String? role;
  final String? date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final sub = [?role, ?date].join(' · ');
    return SsCard(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            top: -14,
            right: 0,
            child: ExcludeSemantics(
              child: Text(
                '“',
                style: TextStyle(fontSize: 72, height: 1, fontWeight: FontWeight.w800, color: c.accentSoft),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: d.gap,
            children: [
              SsRating(rating.clamp(0, 5).toDouble()),
              Text(
                text,
                style: TextStyle(fontSize: AppType.body, height: 1.55, color: c.ink2),
              ),
              Row(
                children: [
                  ExcludeSemantics(child: SsAvatar(name, size: 38)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(fontSize: AppType.set, fontWeight: FontWeight.w700, color: c.ink),
                        ),
                        if (sub.isNotEmpty)
                          Text(
                            sub,
                            style: TextStyle(fontSize: AppType.meta, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pessoa
// ---------------------------------------------------------------------------

/// Pessoa (vendedor, cliente, membro da equipe): avatar com o ponto de
/// [status], nome, papel, as métricas em ladrilhos (borradas no modo
/// privacidade, [SsPrivate]), a equipe em avatares empilhados (4 e "+N") e as
/// [actions] no rodapé, divididas por igual. [onTap] abre a pessoa (o `url:`
/// do web). Par do `Ss::PersonCardComponent`.
///
/// `SsPersonCard(name: 'Ana Souza', role: 'Vendedora · Zona Sul', status: SsTone.success, metrics: [('Vendido', 'R$ 48 mil')], team: ['Bruno', 'Caio'])`
class SsPersonCard extends StatelessWidget {
  const SsPersonCard({
    super.key,
    required this.name,
    this.role,
    this.status,
    this.metrics = const [],
    this.team = const [],
    this.teamLabel,
    this.actions = const [],
    this.onTap,
  });

  final String name;
  final String? role;

  /// Ponto no avatar (o `status:` do web: ok = success, warn = warning…).
  final SsTone? status;

  /// (rótulo, valor).
  final List<(String, String)> metrics;
  final List<String> team;

  /// Padrão: [SsStrings.personTeam].
  final String? teamLabel;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final rotuloEquipe = teamLabel ?? s.personTeam;
    return SsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: d.gap * 1.33,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: SsAvatar(name, size: 56, status: status?.colors(context).solid)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        name,
                        style: TextStyle(fontSize: AppType.md, fontWeight: FontWeight.w800, color: c.ink),
                      ),
                    ),
                    if (role != null)
                      Text(
                        role!,
                        style: TextStyle(fontSize: AppType.sub, color: c.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (metrics.isNotEmpty)
            LayoutBuilder(
              builder: (context, k) {
                // Ladrilhos de no mínimo 104 de largura, divididos por igual.
                final porLinha = math.max(1, math.min(metrics.length, (k.maxWidth + 8) ~/ 112));
                final w = (k.maxWidth - 8 * (porLinha - 1)) / porLinha;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (l, v) in metrics)
                      Container(
                        width: w,
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                        decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(12)),
                        child: MergeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l,
                                style: TextStyle(fontSize: AppType.label, fontWeight: FontWeight.w700, color: c.muted),
                              ),
                              const SizedBox(height: 2),
                              SsPrivate(
                                child: Text(
                                  v,
                                  style: AppTheme.number(context, size: AppType.md, color: c.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          if (team.isNotEmpty)
            Semantics(
              label: '$rotuloEquipe: ${team.join(', ')}',
              excludeSemantics: true,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rotuloEquipe,
                      style: TextStyle(fontSize: AppType.meta, fontWeight: FontWeight.w600, color: c.muted),
                    ),
                  ),
                  SsAvatarStack(team, max: 4, size: 28),
                ],
              ),
            ),
          if (actions.isNotEmpty) Row(spacing: 8, children: [for (final a in actions) Expanded(child: a)]),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mosaico (bento)
// ---------------------------------------------------------------------------

/// Fundo de um bloco do [SsBentoGrid] (os `tone:` do web).
enum SsBentoTone { surface, soft, grad, ink, image }

/// Um bloco do [SsBentoGrid]: ocupa [cols] colunas e [rows] linhas (1 a 4).
class SsBentoBlock {
  const SsBentoBlock({required this.child, this.cols = 1, this.rows = 1, this.tone = SsBentoTone.surface, this.onTap});

  final Widget child;
  final int cols;
  final int rows;
  final SsBentoTone tone;
  final VoidCallback? onTap;
}

/// Mosaico de blocos (Explore): [columns] colunas (4) em tela larga, 2 de 600
/// a 1023 de largura e 1 no celular, como o web; bloco com [SsBentoBlock.cols]
/// e [SsBentoBlock.rows] ocupa mais de uma vaga (no celular, todos ocupam uma
/// e a altura segue o conteúdo). Os blocos sobem em cascata ([SsReveal]).
/// Tons: superfície, `soft` (marca suave), `grad` (o gradiente da marca, texto
/// claro), `ink` (marca bem escura) e `image` (sem respiro, a imagem enche).
/// Par do `Ss::BentoGridComponent`.
///
/// `SsBentoGrid(blocks: [SsBentoBlock(cols: 2, rows: 2, tone: SsBentoTone.grad, child: …), SsBentoBlock(child: …)])`
class SsBentoGrid extends StatelessWidget {
  const SsBentoGrid({super.key, required this.blocks, this.columns = 4, this.rowHeight = 144});

  final List<SsBentoBlock> blocks;
  final int columns;

  /// Altura de uma linha da grade (cresce com o tamanho do texto).
  final double rowHeight;

  /// Colunas para a largura (a do próprio mosaico).
  static int columnsFor(double width, int columns) =>
      width >= 1024 ? columns : (width >= 600 ? math.min(2, columns) : 1);

  /// Posição (linha, coluna) de cada bloco, na ordem, como o auto-posicionamento
  /// do CSS grid (sem `dense`): cada um vai na 1ª vaga livre a partir do anterior.
  static List<(int, int)> place(List<(int, int)> spans, int columns) {
    final ocupado = <(int, int)>{};
    final out = <(int, int)>[];
    var r = 0, col = 0;
    bool cabe(int r0, int c0, int w, int h) {
      if (c0 + w > columns) return false;
      for (var y = r0; y < r0 + h; y++) {
        for (var x = c0; x < c0 + w; x++) {
          if (ocupado.contains((y, x))) return false;
        }
      }
      return true;
    }

    for (final (w0, h) in spans) {
      final w = math.min(w0, columns);
      while (!cabe(r, col, w, h)) {
        col++;
        if (col + w > columns) {
          col = 0;
          r++;
        }
      }
      out.add((r, col));
      for (var y = r; y < r + h; y++) {
        for (var x = col; x < col + w; x++) {
          ocupado.add((y, x));
        }
      }
      col += w;
      if (col >= columns) {
        col = 0;
        r++;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final d = SsDensity.of(context);
    final gap = d.gap * 1.33;
    final alto = MediaQuery.textScalerOf(context).scale(rowHeight);
    return LayoutBuilder(
      builder: (context, k) {
        final n = columnsFor(k.maxWidth, columns);
        if (n == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [
              for (var i = 0; i < blocks.length; i++)
                SsReveal(
                  index: i,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: alto * 8 / 9),
                    child: _Bloco(blocks[i]),
                  ),
                ),
            ],
          );
        }
        final spans = [for (final b in blocks) (b.cols.clamp(1, 4), b.rows.clamp(1, 4))];
        final pos = place(spans, n);
        final colW = (k.maxWidth - gap * (n - 1)) / n;
        var linhas = 0;
        for (var i = 0; i < blocks.length; i++) {
          linhas = math.max(linhas, pos[i].$1 + spans[i].$2);
        }
        return SizedBox(
          height: linhas * alto + (linhas - 1) * gap,
          child: Stack(
            children: [
              for (var i = 0; i < blocks.length; i++)
                Positioned(
                  left: pos[i].$2 * (colW + gap),
                  top: pos[i].$1 * (alto + gap),
                  width: math.min(spans[i].$1, n) * colW + (math.min(spans[i].$1, n) - 1) * gap,
                  height: spans[i].$2 * alto + (spans[i].$2 - 1) * gap,
                  child: SsReveal(index: i, child: _Bloco(blocks[i])),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco(this.b);
  final SsBentoBlock b;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final claro = b.tone == SsBentoTone.grad || b.tone == SsBentoTone.ink;
    final raio = BorderRadius.circular(d.radiusCard);
    final deco = switch (b.tone) {
      SsBentoTone.surface || SsBentoTone.image => BoxDecoration(
        color: c.surface,
        borderRadius: raio,
        border: Border.all(color: c.line),
        boxShadow: AppShadows.card,
      ),
      SsBentoTone.soft => BoxDecoration(color: c.accentSoft, borderRadius: raio),
      SsBentoTone.grad => BoxDecoration(gradient: c.gradient4, borderRadius: raio, boxShadow: c.tintedShadow(c.accent)),
      SsBentoTone.ink => BoxDecoration(
        color: Color.alphaBlend(c.accent.withValues(alpha: .18), AppColors.shadowInk),
        borderRadius: raio,
      ),
    };
    Widget corpo = DefaultTextStyle.merge(
      style: TextStyle(color: claro ? AppColors.onDark : c.ink),
      child: IconTheme.merge(
        data: IconThemeData(color: claro ? AppColors.onDark : c.accentText),
        child: b.child,
      ),
    );
    corpo = Container(
      clipBehavior: Clip.antiAlias,
      decoration: deco,
      padding: b.tone == SsBentoTone.image ? EdgeInsets.zero : EdgeInsets.all(d.cardPad * .92),
      child: corpo,
    );
    if (b.onTap != null) corpo = SsPressable(onTap: b.onTap, scale: .98, child: corpo);
    return corpo;
  }
}
