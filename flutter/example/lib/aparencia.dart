import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

/// Paletas da vitrine (nome → marca), as do pacote.
const paletas = SsBrand.paletas;

/// Tema da vitrine: claro/escuro e paleta.
class Aparencia extends ChangeNotifier {
  ThemeMode modo = ThemeMode.light;
  String paleta = SsBrand.paletas.keys.first;
  bool oled = false;

  /// v0.11: densidade (compacta, padrão, confortável) do tema todo.
  SsDensity densidade = SsDensity.standard;
  final _cache = <String, ThemeData>{};

  ThemeData tema(Brightness b) => _cache.putIfAbsent(
    '$paleta/$b/$oled/${densidade.name}',
    () => AppTheme.build(b, brand: paletas[paleta] ?? SsBrand.violeta, oled: oled, density: densidade),
  );

  /// 'claro', 'escuro' ou 'oled'.
  String get fundo => modo == ThemeMode.light ? 'claro' : (oled ? 'oled' : 'escuro');

  void setFundo(String f) {
    oled = f == 'oled';
    modo = f == 'claro' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setModo(ThemeMode m) {
    modo = m;
    notifyListeners();
  }

  void setDensidade(SsDensity d) {
    densidade = d;
    notifyListeners();
  }

  void setPaleta(String p) {
    paleta = p;
    notifyListeners();
  }
}

class AparenciaScope extends InheritedNotifier<Aparencia> {
  const AparenciaScope({super.key, required Aparencia aparencia, required super.child}) : super(notifier: aparencia);

  static Aparencia of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AparenciaScope>()!.notifier!;

  /// Leva o escopo para uma rota empurrada (a rota nasce fora da árvore da home):
  /// passe o context de quem empurra, não o do builder da rota.
  static Widget copy(BuildContext context, Widget child) => AparenciaScope(aparencia: of(context), child: child);
}

/// Claro/escuro, densidade (v0.11) e paletas.
class AparenciaBar extends StatelessWidget {
  const AparenciaBar({super.key, this.compacta = false});
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final a = AparenciaScope.of(context);
    if (compacta) {
      final escuro = a.modo == ThemeMode.dark;
      // Densidade em ciclo (compacta → padrão → confortável) e claro/escuro.
      final i = SsDensity.values.indexOf(a.densidade);
      final proxima = SsDensity.values[(i + 1) % SsDensity.values.length];
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Densidade: ${a.densidade.name}',
            icon: Icon(
              a.densidade.isCompact
                  ? Icons.density_small_rounded
                  : (a.densidade.isComfortable ? Icons.density_large_rounded : Icons.density_medium_rounded),
            ),
            onPressed: () => a.setDensidade(proxima),
          ),
          IconButton(
            tooltip: escuro ? 'Claro' : 'Escuro',
            icon: Icon(escuro ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => a.setModo(escuro ? ThemeMode.light : ThemeMode.dark),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        SsSegmented<String>(
          segments: const [('claro', 'Claro'), ('escuro', 'Escuro'), ('oled', 'OLED')],
          value: a.fundo,
          onChanged: a.setFundo,
        ),
        SsDensityPicker(value: a.densidade, onChanged: a.setDensidade),
        if (paletas.length > 1)
          SsPalettePicker(
            value: paletas[a.paleta] ?? SsBrand.violeta,
            onChanged: (p) => a.setPaleta(p.nome),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
