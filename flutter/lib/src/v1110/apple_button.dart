// v1.11.0: o botão "Entrar com a Apple" (par do Ss::AppleButtonComponent). Só o botão: a autenticação
// (sign_in_with_apple no app, Sign in with Apple JS no web) é do produto.
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../ss_strings.dart';

/// As três aparências que as Human Interface Guidelines da Apple aceitam.
enum SsAppleButtonStyle {
  /// Fundo preto, logo e texto brancos (sobre fundo claro).
  black,

  /// Fundo branco, logo e texto pretos (sobre fundo escuro).
  white,

  /// Branco com contorno preto (sobre fundo claro que não contrasta com o branco).
  outline,
}

/// O texto do botão: "Continuar com a Apple" (padrão) ou "Entrar com a Apple".
enum SsAppleButtonLabel { continueWith, signIn }

/// v1.11.0: o botão de entrar com a Apple, no desenho das Human Interface Guidelines: o logo da Apple e o
/// texto do idioma do app ([SsStrings.appleContinue]/[SsStrings.appleSignIn]), preto, branco ou branco com
/// contorno, com o raio e a altura do [SsGoogleButton] (50). As cores preta e branca são da Apple e não
/// seguem a paleta do app (a regra da Apple exige essas). [style] nulo escolhe pelo tema: preto no claro,
/// branco no escuro.
///
/// [SsAppleButton.icon] é o quadrado só com o logo, para ficar ao lado do [SsGoogleButton] (o
/// `providers:` do [SsAuthLayout]); a Apple pede que ele não seja menor que os outros botões de entrar.
///
/// Só o botão: o [onPressed] chama a entrada do app (`sign_in_with_apple`). App com entrada por outra conta
/// (Google) que vai para o iOS precisa oferecer a da Apple também (diretriz 4.8 da App Store).
///
/// ```dart
/// SsAppleButton(onPressed: entrarComApple)                       // "Continuar com a Apple", preto
/// SsAppleButton(label: SsAppleButtonLabel.signIn, style: SsAppleButtonStyle.outline, onPressed: …)
/// SsAuthLayout(…, providers: [SsGoogleButton(onTap: g), SsAppleButton.icon(onPressed: a)])
/// ```
class SsAppleButton extends StatelessWidget {
  const SsAppleButton({
    super.key,
    required this.onPressed,
    this.style,
    this.label = SsAppleButtonLabel.continueWith,
    this.text,
  }) : compact = false;

  /// O quadrado só com o logo (50 × 50), do tamanho do [SsGoogleButton]. O leitor de tela lê o texto.
  const SsAppleButton.icon({
    super.key,
    required this.onPressed,
    this.style,
    this.label = SsAppleButtonLabel.continueWith,
    this.text,
  }) : compact = true;

  /// Nulo: desligado (apagado).
  final VoidCallback? onPressed;

  /// Nulo: preto no tema claro, branco no escuro.
  final SsAppleButtonStyle? style;
  final SsAppleButtonLabel label;

  /// Troca o texto (outro idioma, "Cadastrar com a Apple"). Mantenha o "Apple" no texto, como pede a Apple.
  final String? text;

  /// Só o logo.
  final bool compact;

  /// Altura (a do [SsGoogleButton]); cresce com o texto grande.
  static const height = 50.0;
  static const _black = Color(0xFF000000);
  static const _white = AppColors.onDark;

  /// O caminho do logo da Apple numa caixa de 24 × 24 (o mesmo `<path>` do `Ss::AppleButtonComponent`).
  static Path logoPath() => Path()
    ..moveTo(12.152, 6.896)
    ..cubicTo(11.204, 6.896, 9.737, 5.818, 8.192, 5.856)
    ..cubicTo(6.152, 5.883, 4.282, 7.039, 3.231, 8.87)
    ..cubicTo(1.114, 12.545, 2.685, 17.973, 4.75, 20.96)
    ..cubicTo(5.763, 22.414, 6.958, 24.05, 8.542, 23.999)
    ..cubicTo(10.062, 23.934, 10.632, 23.012, 12.477, 23.012)
    ..cubicTo(14.308, 23.012, 14.827, 23.999, 16.437, 23.96)
    ..cubicTo(18.074, 23.934, 19.113, 22.48, 20.113, 21.012)
    ..cubicTo(21.269, 19.324, 21.749, 17.687, 21.775, 17.597)
    ..cubicTo(21.736, 17.584, 18.593, 16.376, 18.555, 12.74)
    ..cubicTo(18.529, 9.7, 21.035, 8.246, 21.152, 8.181)
    ..cubicTo(19.723, 6.091, 17.529, 5.857, 16.762, 5.805)
    ..cubicTo(14.762, 5.649, 13.087, 6.895, 12.152, 6.895)
    ..close()
    ..moveTo(15.53, 3.83)
    ..cubicTo(16.373, 2.818, 16.93, 1.403, 16.775, 0)
    ..cubicTo(15.568, 0.052, 14.113, 0.805, 13.243, 1.818)
    ..cubicTo(12.463, 2.714, 11.789, 4.156, 11.97, 5.532)
    ..cubicTo(13.308, 5.636, 14.685, 4.844, 15.529, 3.831)
    ..close();

  /// O texto que o botão mostra (e o leitor de tela lê).
  String labelText(BuildContext context) {
    final s = SsStrings.of(context);
    return text ?? (label == SsAppleButtonLabel.signIn ? s.appleSignIn : s.appleContinue);
  }

  /// A aparência efetiva (com [style] nulo, a do tema).
  SsAppleButtonStyle effectiveStyle(BuildContext context) =>
      style ?? (SsColors.of(context).isDark ? SsAppleButtonStyle.white : SsAppleButtonStyle.black);

  @override
  Widget build(BuildContext context) {
    final estilo = effectiveStyle(context);
    final preto = estilo == SsAppleButtonStyle.black;
    final fundo = preto ? _black : _white;
    final tinta = preto ? _white : _black;
    final radius = BorderRadius.circular(14);
    final rotulo = labelText(context);
    final escala = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final logo = SizedBox.square(
      dimension: 20 * escala,
      child: CustomPaint(painter: _LogoPainter(tinta)),
    );
    final conteudo = compact
        ? Center(child: logo)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logo,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  rotulo,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    color: tinta,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.2,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          );
    Widget botao = Semantics(
      button: true,
      enabled: onPressed != null,
      label: rotulo,
      excludeSemantics: true,
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? .5 : 1,
        child: Material(
          color: fundo,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            splashColor: tinta.withValues(alpha: .12),
            highlightColor: tinta.withValues(alpha: .06),
            child: Container(
              constraints: BoxConstraints(minHeight: height, minWidth: compact ? height : 140),
              width: compact ? height * escala : null,
              padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: estilo == SsAppleButtonStyle.outline
                    ? Border.all(color: _black)
                    : (estilo == SsAppleButtonStyle.white && !SsColors.of(context).isDark
                          ? Border.all(color: SsColors.of(context).line)
                          : null),
              ),
              child: conteudo,
            ),
          ),
        ),
      ),
    );
    if (compact) botao = Tooltip(message: rotulo, child: botao);
    return botao;
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 24;
    canvas
      ..save()
      ..scale(k)
      ..drawPath(SsAppleButton.logoPath(), Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
