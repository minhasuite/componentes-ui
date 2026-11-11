// v0.19.2: as últimas caixas genéricas que o minhas-compras-app e o
// minhas-viagens-app ainda desenhavam à mão: ponto de estado, monograma de
// loja/site, recado entre aspas, palco da ilustração e indicador de página.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_strings.dart';

// ── Ponto ─────────────────────────────────────────────────────────────────

/// Ponto de estado ou de "não lida": um círculo cheio na [color] (padrão a
/// cor da marca), com [ring] opcional (anel na cor do fundo, para o ponto que
/// encosta num ícone; ex. `ring: SsColors.of(context).surface`). O web é o
/// `.ss-dot` (`--ss-dot`). Cor nunca vai sozinha: passe [semanticLabel] (ou
/// deixe o texto ao lado dizer o estado).
///
/// `SsDot(semanticLabel: SsStrings.of(context).unread)` · `SsDot(color: AppColors.success, size: 10)`
class SsDot extends StatelessWidget {
  const SsDot({super.key, this.color, this.size = 8, this.ring, this.semanticLabel});

  final Color? color;
  final double size;

  /// Cor do anel de 2 px em volta (o ponto cresce 4 para fora).
  final Color? ring;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: ring == null ? size : size + 4,
      height: ring == null ? size : size + 4,
      decoration: BoxDecoration(
        color: color ?? SsColors.of(context).accent,
        shape: BoxShape.circle,
        border: ring == null ? null : Border.all(color: ring!, width: 2),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: dot);
    return Semantics(label: semanticLabel, excludeSemantics: true, child: dot);
  }
}

// ── Monograma ─────────────────────────────────────────────────────────────

/// Sigla de uma loja, site ou companhia num quadrado arredondado (raio
/// `size / 4`) ou num círculo ([circle]), em texto claro que encolhe para
/// caber ("a", "ML", "Ali"). [color] é a cor de marca do terceiro, que é
/// **dado** (`ssColorFromHex('#E43225')`); sem ela, a cor da marca do
/// produto. Para nome de pessoa, use o [SsAvatar]. O web é o `ss_monogram`
/// (`.ss-monogram`).
///
/// `SsMonogram('ML', color: ssColorFromHex('#2D3277'), size: 20, semanticLabel: 'Mercado Livre')`
class SsMonogram extends StatelessWidget {
  const SsMonogram(this.text, {super.key, this.color, this.size = 20, this.circle = false, this.semanticLabel});

  final String text;
  final Color? color;
  final double size;
  final bool circle;

  /// O nome por extenso para o leitor de tela (padrão: a sigla).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel ?? text,
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * (circle ? .16 : .1)),
      decoration: BoxDecoration(
        color: color ?? SsColors.of(context).accentSolid,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size / 4),
      ),
      child: FittedBox(
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            color: AppColors.onDark,
            fontSize: size * .56,
            fontWeight: FontWeight.w800,
            height: AppType.solid,
          ),
        ),
      ),
    ),
  );
}

// ── Recado ────────────────────────────────────────────────────────────────

/// Recado de outra pessoa dentro de um card (o texto que ela escreveu na
/// doação, no pedido, no comentário): balão no fundo do campo com o canto
/// de cima à esquerda reto, texto em itálico entre aspas e, opcional, o
/// [author] embaixo. Não é o [SsChatBubble] (conversa com a IA, que entra
/// com mola e se alinha pelo remetente). O web é o `.ss-quote`.
class SsQuote extends StatelessWidget {
  const SsQuote(this.text, {super.key, this.author, this.quoted = true});

  final String text;
  final String? author;

  /// Falso tira as aspas (o texto já vem com elas).
  final bool quoted;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    const r = Radius.circular(14);
    return Semantics(
      container: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: d.space(12), vertical: d.space(8)),
        decoration: BoxDecoration(
          color: c.field,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: r,
            bottomLeft: r,
            bottomRight: r,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              quoted ? '“$text”' : text,
              style: TextStyle(
                color: c.ink2,
                fontSize: d.font(AppType.sub),
                fontStyle: FontStyle.italic,
                height: AppType.leading,
              ),
            ),
            if (author != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '— $author',
                  style: TextStyle(color: c.muted, fontSize: d.font(AppType.label), fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Palco da ilustração ───────────────────────────────────────────────────

/// O palco de uma ilustração (passo do onboarding, abertura de recurso):
/// degradê suave da cor da marca descendo para a cor da página, raio de
/// folha, e a ilustração encolhida para caber na [height] (assim o botão do
/// passo cabe sem rolar). Sem cor fixa: `accentSoft` → `page`.
class SsIllustrationStage extends StatelessWidget {
  const SsIllustrationStage({super.key, required this.child, this.height = 112, this.padding});

  final Widget child;
  final double height;

  /// Respiro em volta (padrão: 12 em cima e embaixo).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.accentSoft, c.page],
        ),
      ),
      child: SizedBox(
        height: height,
        child: FittedBox(child: child),
      ),
    );
  }
}

// ── Indicador de página ───────────────────────────────────────────────────

/// Indicador de página em pílulas: a atual estica (3× o [size]) na cor da
/// marca, com a mola da suíte (sem animação com "reduzir movimento"). O
/// leitor de tela lê "Página 2 de 3" ([SsStrings.pageOf]). É o mesmo do
/// [SsOnboarding], para quando os passos têm formulário e só avançam ao
/// salvar. O web é o `.ss-dots` com `aria-current`.
class SsPageDots extends StatelessWidget {
  const SsPageDots({super.key, required this.count, required this.index, this.size = 8, this.alignment});

  final int count;
  final int index;
  final double size;

  /// Padrão: centro.
  final MainAxisAlignment? alignment;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final reduce = reduceMotion(context);
    return Semantics(
      label: SsStrings.of(context).pageOf(index + 1, count),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignment ?? MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: reduce ? Duration.zero : SsMotion.base,
              curve: SsMotion.spring,
              margin: EdgeInsets.symmetric(horizontal: size * .375),
              width: i == index ? size * 3 : size,
              height: size,
              decoration: BoxDecoration(
                color: i == index ? c.accent : c.muted2,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}
