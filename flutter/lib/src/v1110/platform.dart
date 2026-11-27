// v1.11.0 "adaptativa": em que plataforma a peça está desenhando e a saída para o app que quer o desenho
// da suíte em todo lugar.
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';

/// v1.11.0: a plataforma que as peças adaptativas usam para decidir o desenho.
///
/// Lê `Theme.of(context).platform` (não o `Platform.isIOS`): no celular é a do aparelho, e o teste ou o
/// catálogo trocam por `ThemeData(platform: TargetPlatform.iOS)` ou `debugDefaultTargetPlatformOverride`.
/// iOS e macOS contam como Apple (o iPad é iOS).
///
/// Cada peça adaptativa tem `adaptive` (padrão `true`); com `false`, ela fica no desenho da suíte mesmo no
/// iOS. Para o app inteiro, ponha um [SsPlatformScope] com `adaptive: false` acima do `MaterialApp.home`
/// (ou no `builder:`).
///
/// ```dart
/// if (SsPlatform.cupertino(context)) { … }          // vale o SsPlatformScope
/// SsSwitch(value: v, onChanged: f, adaptive: false) // a chave da suíte também no iPhone
/// ```
abstract final class SsPlatform {
  /// Até quantos itens o `showSsPicker` vira a folha de ação do iOS (mais que isso, a folha de busca).
  static const actionSheetMax = 8;

  /// A plataforma do tema.
  static TargetPlatform of(BuildContext context) => Theme.of(context).platform;

  /// iOS ou macOS (o desenho da Apple).
  static bool isApple(BuildContext context) => _apple(of(context));

  static bool _apple(TargetPlatform p) => p == TargetPlatform.iOS || p == TargetPlatform.macOS;

  /// A peça deve usar a variante da Apple? Só com [adaptive], com o [SsPlatformScope] deixando e no iOS/macOS.
  static bool cupertino(BuildContext context, {bool adaptive = true}) =>
      adaptive && SsPlatformScope.adaptiveOf(context) && isApple(context);

  /// O mesmo de [cupertino] para quem não tem `context` (o [SsHaptics]): lê o `defaultTargetPlatform`.
  static bool get cupertinoDefault => _apple(defaultTargetPlatform);

  /// O ícone de voltar: a seta da suíte, ou o "‹" do iOS.
  static IconData backIcon(BuildContext context) =>
      cupertino(context) ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded;

  /// A rolagem da lista: com elástico no iOS ([BouncingScrollPhysics]) e presa no Android. As listas do
  /// pacote já pegam isso do `ScrollConfiguration` do `MaterialApp` (que lê a plataforma do tema); use
  /// aqui quando a lista do app passa `physics:` próprio.
  static ScrollPhysics scrollPhysics(BuildContext context, {bool adaptive = true, bool always = false}) {
    final ScrollPhysics base = cupertino(context, adaptive: adaptive)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    return always ? AlwaysScrollableScrollPhysics(parent: base) : base;
  }
}

/// v1.11.0: liga ou desliga as variantes da Apple de tudo que está abaixo. Com `adaptive: false`, as peças
/// do pacote ficam no desenho da suíte também no iOS: chave, data e hora, menus, confirmação, puxar para
/// atualizar, rolagem (presa, sem elástico) e o voltar (a alça do menu lateral não some na rota empilhada).
///
/// ```dart
/// MaterialApp(builder: (context, child) => SsPlatformScope(adaptive: false, child: child!), …)
/// ```
class SsPlatformScope extends StatelessWidget {
  const SsPlatformScope({super.key, this.adaptive = true, required this.child});

  final bool adaptive;
  final Widget child;

  /// Sem escopo acima: `true`.
  static bool adaptiveOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Scope>()?.adaptive ?? true;

  @override
  Widget build(BuildContext context) => _Scope(
    adaptive: adaptive,
    child: adaptive
        ? child
        : ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(physics: const ClampingScrollPhysics()),
            child: child,
          ),
  );
}

class _Scope extends InheritedWidget {
  const _Scope({required this.adaptive, required super.child});
  final bool adaptive;

  @override
  bool updateShouldNotify(_Scope old) => old.adaptive != adaptive;
}
