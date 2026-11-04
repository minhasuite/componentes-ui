import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'ss_button.dart';
import 'ss_strings.dart';

/// View de erro padronizada (ícone + mensagem + "Tentar de novo" opcional).
/// Substitui os ~7 `_Retry`/`_ErrorView` duplicados.
class SsErrorView extends StatelessWidget {
  const SsErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: c.muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.ink2, fontSize: AppType.body),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              SsButton(
                label: SsStrings.of(context).retry,
                icon: Icons.refresh,
                variant: SsButtonVariant.ghost,
                expand: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
