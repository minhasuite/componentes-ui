import 'package:material_ui/material_ui.dart';

import 'ss_auth_folhinha.dart';
import 'ss_strings.dart';
import 'v170/auth_cartaz.dart';

// Tela de entrada padrão da suíte (o modelo é o login do meu-financeiro).
// Arquivo idêntico em todos os apps: só usa o ColorScheme, então não depende
// dos tokens de cada um. Ao mudar aqui, copie para os outros apps.

/// Halos da marca atrás do formulário, ícone do app, nome, frase e o formulário.
class SsAuthLayout extends StatelessWidget {
  const SsAuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.halo,
    required this.children,
  });

  /// v0.22: a tela de entrada "Folhinha" (par do `Ss::AuthLayoutComponent`): folhinha de parede com a data
  /// de hoje, o formulário do app no bloco e a faixa do [product] na cor da marca. Três variações
  /// ([SsAuthVariant.sheet], [SsAuthVariant.wall], [SsAuthVariant.pad]). O construtor padrão (halos e ícone)
  /// continua igual: o app só muda quando escolher a folhinha.
  ///
  ///     SsAuthLayout.folhinha(product: 'Meu Gestor', tagline: 'A loja em dia, sem planilha.',
  ///       title: 'Entrar', subtitle: 'no Meu Gestor', children: [SsTextField(...), SsButton(...)])
  static Widget folhinha({
    Key? key,
    required String product,
    required String title,
    required List<Widget> children,
    String? subtitle,
    String? tagline,
    SsAuthVariant variant = SsAuthVariant.sheet,
    DateTime? date,
    String? note,
    (String, String) brand = const ('Minha', 'Suite'),
    List<Widget> footer = const [],
  }) => SsAuthFolhinha(
    key: key,
    product: product,
    title: title,
    subtitle: subtitle,
    tagline: tagline,
    variant: variant,
    date: date,
    note: note,
    brand: brand,
    footer: footer,
    children: children,
  );

  /// v1.7: a tela de entrada "Cartaz + papel" (par do `Ss::AuthLayoutComponent(variant: :cartaz, layout: :split)`):
  /// metade cartaz na cor funda da marca ([SsColors.brandDeep]) com o [product], o [tagline] grande, a linha de
  /// dados [facts] e a palavra gigante [word] (padrão: a última palavra do produto) cortada pela borda; metade papel
  /// com "Parte da MinhaSuite", o título e o formulário do app. Abaixo de 840 de largura, o cartaz vira uma faixa
  /// em cima. Uma passada de cor ao abrir; "reduzir movimento" desliga.
  ///
  ///     SsAuthLayout.cartaz(product: 'Minhas Vendas', tagline: 'A venda não para.', word: 'vendas',
  ///       facts: const ['Web', 'Windows', 'Caixa', 'App'], title: 'Entrar', subtitle: 'no Minhas Vendas',
  ///       children: [SsTextField(...), SsButton(...)])
  static Widget cartaz({
    Key? key,
    required String product,
    required String title,
    required List<Widget> children,
    String? subtitle,
    String? tagline,
    String? word,
    SsCartazLayout layout = SsCartazLayout.split,
    List<String> facts = const [],
    IconData? icon,
    (String, String) brand = const ('Minha', 'Suite'),
    List<Widget> footer = const [],
  }) => SsAuthCartaz(
    key: key,
    product: product,
    title: title,
    subtitle: subtitle,
    tagline: tagline,
    word: word,
    layout: layout,
    facts: facts,
    icon: icon,
    brand: brand,
    footer: footer,
    children: children,
  );

  final String title;
  final String subtitle;

  /// Cores dos dois halos (canto de cima e canto de baixo).
  final (Color, Color) halo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(top: -160, left: -120, child: _Halo(color: halo.$1)),
        Positioned(bottom: -180, right: -140, child: _Halo(color: halo.$2)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 72,
                      width: 72,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: halo.$1.withValues(alpha: .4),
                            offset: const Offset(0, 18),
                            blurRadius: 40,
                            spreadRadius: -14,
                          ),
                        ],
                      ),
                      child: Image.asset('assets/branding/icon.png', semanticLabel: title),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: s.onSurface,
                        letterSpacing: -0.56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: s.onSurfaceVariant, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 420,
      height: 420,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: .28), color.withValues(alpha: 0)]),
      ),
    ),
  );
}

/// Caixa de erro do formulário.
class SsAuthError extends StatelessWidget {
  const SsAuthError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error.withValues(alpha: .08),
        border: Border.all(color: error.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(color: error),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Botão quadrado "G" do Google, ao lado do botão de entrar.
class SsGoogleButton extends StatelessWidget {
  const SsGoogleButton({super.key, required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(14);
    return Tooltip(
      message: SsStrings.of(context).signInWithGoogle,
      child: Material(
        color: s.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: s.outlineVariant),
            ),
            padding: const EdgeInsets.all(13),
            // O asset vem espelhado e de cabeça para baixo: girar 180° corrige.
            child: Transform.flip(flipX: true, flipY: true, child: Image.asset('assets/branding/google_g.png')),
          ),
        ),
      ),
    );
  }
}
