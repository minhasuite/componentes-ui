// v1.3: aparência escolhida pela pessoa (tema, preto total, cores e densidade), igual em todos
// os apps: o valor ([SsAppearance]), quem guarda e monta o tema ([SsAppearanceController]) e a
// seção pronta da tela de configurações ([SsAppearancePanel]).
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../ss_controls.dart' show SsSegmented;
import '../ss_fields.dart' show SsFieldLabel, SsSwitchRow;
import '../ss_palette_picker.dart';
import '../ss_strings.dart';

/// O que a pessoa escolheu. [paleta] nulo = a cor do app (a marca do produto).
@immutable
class SsAppearance {
  const SsAppearance({
    this.paleta,
    this.themeMode = ThemeMode.system,
    this.oled = false,
    this.density = SsDensity.standard,
  });

  /// Slug de uma das paletas prontas ([SsPaleta.slug]); nulo = cor do app.
  final String? paleta;
  final ThemeMode themeMode;

  /// Preto total no tema escuro.
  final bool oled;
  final SsDensity density;

  SsAppearance copyWith({
    String? paleta,
    bool clearPaleta = false,
    ThemeMode? themeMode,
    bool? oled,
    SsDensity? density,
  }) => SsAppearance(
    paleta: clearPaleta ? null : (paleta ?? this.paleta),
    themeMode: themeMode ?? this.themeMode,
    oled: oled ?? this.oled,
    density: density ?? this.density,
  );

  String toJson() => jsonEncode({'paleta': ?paleta, 'tema': themeMode.name, 'oled': oled, 'densidade': density.name});

  /// Lê o que [toJson] gravou; texto vazio, inválido ou de outra versão vira o padrão.
  static SsAppearance fromJson(String? texto) {
    if (texto == null || texto.isEmpty) return const SsAppearance();
    try {
      final m = jsonDecode(texto) as Map<String, dynamic>;
      final slug = m['paleta'] as String?;
      return SsAppearance(
        paleta: slug != null && SsPaleta.porSlug(slug) != null ? slug : null,
        themeMode: ThemeMode.values.firstWhere((t) => t.name == m['tema'], orElse: () => ThemeMode.system),
        oled: m['oled'] == true,
        density: SsDensity.values.firstWhere((d) => d.name == m['densidade'], orElse: () => SsDensity.standard),
      );
    } catch (_) {
      return const SsAppearance();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SsAppearance &&
      other.paleta == paleta &&
      other.themeMode == themeMode &&
      other.oled == oled &&
      other.density == density;

  @override
  int get hashCode => Object.hash(paleta, themeMode, oled, density);
}

/// Guarda a [SsAppearance] (o app diz onde: [read]/[write] de um texto, ex. o
/// `flutter_secure_storage` ou o `shared_preferences` que ele já usa) e monta os temas, um por
/// combinação, em cache (`AppTheme.build` é caro).
///
/// ```dart
/// final aparencia = SsAppearanceController(
///   brand: SsBrand.ambar,                       // a cor do app
///   read: () => storage.read(key: 'aparencia'),
///   write: (v) => storage.write(key: 'aparencia', value: v),
/// )..load();
/// ListenableBuilder(
///   listenable: aparencia,
///   builder: (_, _) => MaterialApp(
///     theme: aparencia.theme(Brightness.light),
///     darkTheme: aparencia.theme(Brightness.dark),
///     themeMode: aparencia.value.themeMode,
///   ),
/// );
/// ```
class SsAppearanceController extends ChangeNotifier {
  SsAppearanceController({
    required this.brand,
    required this.read,
    required this.write,
    SsAppearance initial = const SsAppearance(),
    this.highContrast = false,
  }) : _value = initial;

  /// A cor do app (a 1ª opção das cores, e a usada sem paleta escolhida).
  final SsBrand brand;
  final bool highContrast;

  /// Lê o texto guardado (nulo = nada guardado).
  final Future<String?> Function() read;

  /// Guarda o texto ([SsAppearance.toJson]).
  final Future<void> Function(String value) write;
  final _temas = <String, ThemeData>{};

  SsAppearance _value;
  SsAppearance get value => _value;

  /// A marca em uso: a da paleta escolhida ou a do app.
  SsBrand get effectiveBrand => (_value.paleta == null ? null : SsPaleta.porSlug(_value.paleta!))?.brand ?? brand;

  /// Lê o valor guardado (chame uma vez, no início).
  Future<void> load() async {
    final lido = SsAppearance.fromJson(await read());
    if (lido == _value) return;
    _value = lido;
    notifyListeners();
  }

  /// Troca e guarda.
  Future<void> set(SsAppearance novo) async {
    if (novo == _value) return;
    _value = novo;
    notifyListeners();
    await write(novo.toJson());
  }

  /// O tema para o brilho dado, com a paleta, o preto total e a densidade escolhidos.
  ThemeData theme(Brightness brightness) {
    final oled = brightness == Brightness.dark && _value.oled;
    final chave = '${brightness.name}/${_value.paleta ?? '-'}/$oled/${_value.density.name}/$highContrast';
    return _temas.putIfAbsent(
      chave,
      () => AppTheme.build(
        brightness,
        brand: effectiveBrand,
        oled: oled,
        density: _value.density,
        highContrast: highContrast,
      ),
    );
  }
}

/// A seção de Aparência das configurações, igual em todos os apps: tema (claro, escuro ou do
/// sistema), preto total no escuro, cores (a do app primeiro, depois as paletas da suíte) e
/// densidade. Muda na hora (o [controller] avisa o `MaterialApp`).
class SsAppearancePanel extends StatelessWidget {
  const SsAppearancePanel({super.key, required this.controller, this.density = true, this.paletas = SsPaleta.todas});

  final SsAppearanceController controller;

  /// Mostra a escolha de densidade.
  final bool density;

  /// As paletas oferecidas (todas por padrão).
  final List<SsPaleta> paletas;

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final v = controller.value;
        final doApp = SsPaleta(slug: '', nome: s.appearanceAppColor, familia: '', brand: controller.brand);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SsFieldLabel(s.appearanceTheme, icon: Icons.brightness_6_outlined),
            const SizedBox(height: 8),
            SsSegmented<ThemeMode>(
              segments: [
                (ThemeMode.light, s.themeLight),
                (ThemeMode.dark, s.themeDark),
                (ThemeMode.system, s.themeSystem),
              ],
              value: v.themeMode,
              onChanged: (t) => controller.set(v.copyWith(themeMode: t)),
            ),
            if (v.themeMode != ThemeMode.light) ...[
              const SizedBox(height: 8),
              SsSwitchRow(
                icon: Icons.dark_mode_outlined,
                title: s.appearanceOled,
                subtitle: s.appearanceOledHint,
                value: v.oled,
                onChanged: (o) => controller.set(v.copyWith(oled: o)),
              ),
            ],
            const SizedBox(height: 16),
            SsFieldLabel(s.appearanceColors, icon: Icons.palette_outlined),
            const SizedBox(height: 8),
            SsPalettePicker(
              value: controller.effectiveBrand,
              paletas: [doApp, ...paletas.where((p) => p.brand != controller.brand)],
              padding: EdgeInsets.zero,
              onChanged: (p) =>
                  controller.set(p.slug.isEmpty ? v.copyWith(clearPaleta: true) : v.copyWith(paleta: p.slug)),
            ),
            if (density) ...[
              const SizedBox(height: 16),
              SsFieldLabel(s.densityLabel, icon: Icons.density_medium_rounded),
              const SizedBox(height: 8),
              SsDensityPicker(
                value: v.density,
                onChanged: (d) => controller.set(v.copyWith(density: d)),
              ),
            ],
          ],
        );
      },
    );
  }
}
