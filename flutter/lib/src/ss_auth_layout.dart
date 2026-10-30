import 'package:flutter/material.dart';

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
      message: 'Entrar com Google',
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
