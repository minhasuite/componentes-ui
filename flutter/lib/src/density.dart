import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'ss_controls.dart' show SsSegmented;
import 'ss_strings.dart';

/// Densidade da interface (v0.11): altura dos controles, espaçamento, raio,
/// ícone e um leve ajuste de fonte, iguais ao `data-ss-density` do web.
///
/// - [compact]: mais coisa por tela (tabela, painel, tablet, desktop);
/// - [standard]: o padrão;
/// - [comfortable]: alvos e respiros maiores (toque, pouca visão, quiosque).
///
/// Vem do tema (`AppTheme.build(b, density: SsDensity.compact)`) e pode mudar
/// num trecho da árvore com [SsDensityScope]. Os `Ss*` leem com
/// `SsDensity.of(context)`. O alvo de toque nunca cai abaixo de [minTarget]
/// (48): no compacto o desenho encolhe, a área de toque não (ver [SsTapTarget]).
@immutable
class SsDensity extends ThemeExtension<SsDensity> {
  const SsDensity._({
    required this.name,
    required this.controlHeight,
    required this.controlHeightSmall,
    required this.fieldHeight,
    required this.chipHeight,
    required this.segmentHeight,
    required this.iconButton,
    required this.padX,
    required this.gap,
    required this.rowPadV,
    required this.cardPad,
    required this.radiusField,
    required this.radiusCard,
    required this.iconSize,
    required this.iconTile,
    required this.fontScale,
    required this.spaceScale,
    required this.visualDensity,
  });

  /// `compact`, `standard` ou `comfortable` (o mesmo do `data-ss-density`).
  final String name;

  /// Botão (`SsButton`): 40 / 48 / 52.
  final double controlHeight;

  /// Botão pequeno e botão de texto: 32 / 36 / 40.
  final double controlHeightSmall;

  /// Campo de texto, escolha, data, hora: 44 / 52 / 56.
  final double fieldHeight;

  /// Chip de filtro: 30 / 34 / 38.
  final double chipHeight;

  /// Segmented (pílula com as opções): 36 / 42 / 46.
  final double segmentHeight;

  /// Botão só de ícone (`SsIconButton`), o desenho: 36 / 40 / 44.
  final double iconButton;

  /// Respiro lateral de botão, campo e linha: 12 / 16 / 20.
  final double padX;

  /// Espaço entre itens (ícone e texto, chips, linhas de formulário): 8 / 12 / 14.
  final double gap;

  /// Respiro vertical da linha de lista (`SsListItem`, `SsRows`): 6 / 10 / 14.
  final double rowPadV;

  /// Respiro do card (`SsCard`, tiles): 12 / 16 / 20.
  final double cardPad;

  /// Raio de campo e botão: 12 / 14 / 16.
  final double radiusField;

  /// Raio de card: 16 / 18 / 20.
  final double radiusCard;

  /// Ícone dentro de controle: 18 / 20 / 22.
  final double iconSize;

  /// Quadrado tonal do ícone (`SsIconTile`, `SsListItem`): 36 / 42 / 46.
  final double iconTile;

  /// Multiplica o tamanho da fonte dos controles: 0,94 / 1 / 1,05.
  final double fontScale;

  /// Multiplica os respiros que não têm token próprio: 0,75 / 1 / 1,2.
  final double spaceScale;

  /// O `ThemeData.visualDensity` alinhado (os widgets Material que sobram).
  final VisualDensity visualDensity;

  /// Alvo de toque mínimo (Material/WCAG), igual nas três densidades.
  double get minTarget => 48;

  static const compact = SsDensity._(
    name: 'compact',
    controlHeight: 40,
    controlHeightSmall: 32,
    fieldHeight: 44,
    chipHeight: 30,
    segmentHeight: 36,
    iconButton: 36,
    padX: 12,
    gap: 8,
    rowPadV: 6,
    cardPad: 12,
    radiusField: 12,
    radiusCard: 16,
    iconSize: 18,
    iconTile: 36,
    fontScale: .94,
    spaceScale: .75,
    visualDensity: VisualDensity.compact,
  );

  static const standard = SsDensity._(
    name: 'standard',
    controlHeight: 48,
    controlHeightSmall: 36,
    fieldHeight: 52,
    chipHeight: 34,
    segmentHeight: 42,
    iconButton: 40,
    padX: 16,
    gap: 12,
    rowPadV: 10,
    cardPad: 16,
    radiusField: 14,
    radiusCard: 18,
    iconSize: 20,
    iconTile: 42,
    fontScale: 1,
    spaceScale: 1,
    visualDensity: VisualDensity.standard,
  );

  static const comfortable = SsDensity._(
    name: 'comfortable',
    controlHeight: 52,
    controlHeightSmall: 40,
    fieldHeight: 56,
    chipHeight: 38,
    segmentHeight: 46,
    iconButton: 44,
    padX: 20,
    gap: 14,
    rowPadV: 14,
    cardPad: 20,
    radiusField: 16,
    radiusCard: 20,
    iconSize: 22,
    iconTile: 46,
    fontScale: 1.05,
    spaceScale: 1.2,
    visualDensity: VisualDensity.comfortable,
  );

  /// As três, na ordem do seletor.
  static const values = [compact, standard, comfortable];

  /// Pelo nome (`compact`/`standard`/`comfortable`; também `compacta`,
  /// `padrao`, `confortavel`). Nome desconhecido: [standard].
  static SsDensity byName(String? name) => switch (name) {
    'compact' || 'compacta' || 'compacto' => compact,
    'comfortable' || 'confortavel' || 'confortável' => comfortable,
    _ => standard,
  };

  /// A densidade em vigor: a do [SsDensityScope] mais próximo, senão a do
  /// tema, senão [standard].
  static SsDensity of(BuildContext context) =>
      SsDensityScope.maybeOf(context) ?? Theme.of(context).extension<SsDensity>() ?? standard;

  bool get isCompact => identical(this, compact) || name == 'compact';
  bool get isComfortable => identical(this, comfortable) || name == 'comfortable';

  /// Fonte de controle na densidade (`d.font(AppType.body)`).
  double font(double size) => size * fontScale;

  /// Respiro sem token próprio, na escala da densidade (`d.space(10)`).
  double space(double v) => v * spaceScale;

  /// Altura que leva em conta o alvo de toque: o maior entre [h] e [minTarget].
  double target(double h) => math.max(h, minTarget);

  @override
  SsDensity copyWith() => this;

  @override
  SsDensity lerp(SsDensity? other, double t) => t < .5 || other == null ? this : other;

  @override
  String toString() => 'SsDensity.$name';
}

/// Troca a densidade num trecho da árvore (uma tabela compacta dentro de uma
/// tela padrão, um quiosque confortável). Também alinha o
/// `ThemeData.visualDensity` do trecho, para os widgets Material que sobram.
class SsDensityScope extends StatelessWidget {
  const SsDensityScope({super.key, required this.density, required this.child});

  final SsDensity density;
  final Widget child;

  static SsDensity? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SsDensityInherited>()?.density;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return _SsDensityInherited(
      density: density,
      child: Theme(
        data: t.copyWith(
          visualDensity: density.visualDensity,
          extensions: [...t.extensions.values.where((e) => e is! SsDensity), density],
        ),
        child: child,
      ),
    );
  }
}

class _SsDensityInherited extends InheritedWidget {
  const _SsDensityInherited({required this.density, required super.child});
  final SsDensity density;

  @override
  bool updateShouldNotify(_SsDensityInherited old) => old.density != density;
}

/// Alvo de toque mínimo sem mudar o desenho nem o layout: o filho continua do
/// tamanho dele e o toque vale numa área de pelo menos [minSize] em volta
/// (centrada), levada para o meio do filho no eixo em que caiu fora. É o que deixa o
/// compacto desenhar 40 e continuar com 48 de toque. A sobra só recebe toque
/// dentro do pai (quem desenha o controle numa linha de 48 já tem a área).
class SsTapTarget extends SingleChildRenderObjectWidget {
  const SsTapTarget({super.key, this.minSize = const Size(48, 48), required Widget super.child});

  final Size minSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSsTapTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSsTapTarget).minSize = minSize;
  }
}

class _RenderSsTapTarget extends RenderProxyBox {
  _RenderSsTapTarget(this.minSize);

  Size minSize;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final dx = math.max(0.0, (minSize.width - size.width) / 2);
    final dy = math.max(0.0, (minSize.height - size.height) / 2);
    final area = Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
    if (!area.contains(position)) return false;
    if (size.isEmpty) return false;
    // Ponto da sobra vai para o meio do filho no eixo em que caiu fora (a borda
    // pode ser respiro interno, que não recebe toque).
    final p = Offset(
      position.dx >= 0 && position.dx < size.width ? position.dx : size.width / 2,
      position.dy >= 0 && position.dy < size.height ? position.dy : size.height / 2,
    );
    if (hitTestChildren(result, position: p) || hitTestSelf(p)) {
      result.add(BoxHitTestEntry(this, p));
      return true;
    }
    return false;
  }
}

/// Seletor de densidade (Compacta, Padrão, Confortável), o
/// `Ss::DensityPickerComponent` do web: um [SsSegmented] com a pílula que
/// desliza. Só escolhe; guardar a preferência e reconstruir o tema
/// (`AppTheme.build(b, density: ...)`) é do app, que decide se mostra.
///
/// ```dart
/// SsDensityPicker(value: densidade, onChanged: (d) => setState(() => densidade = d))
/// ```
class SsDensityPicker extends StatelessWidget {
  const SsDensityPicker({super.key, required this.value, required this.onChanged, this.icons = true});

  final SsDensity value;
  final ValueChanged<SsDensity> onChanged;

  /// Ícone antes de cada opção.
  final bool icons;

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    return Semantics(
      container: true,
      label: s.densityLabel,
      child: SsSegmented<String>(
        segments: [
          ('compact', s.densityCompact),
          ('standard', s.densityStandard),
          ('comfortable', s.densityComfortable),
        ],
        icons: icons
            ? const [Icons.density_small_rounded, Icons.density_medium_rounded, Icons.density_large_rounded]
            : null,
        value: value.name,
        onChanged: (n) => onChanged(SsDensity.byName(n)),
      ),
    );
  }
}
