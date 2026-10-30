import 'package:flutter/material.dart';

/// Movimento do design system: tudo aqui some quando o sistema pede menos
/// animação (Acessibilidade → remover animações).
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
