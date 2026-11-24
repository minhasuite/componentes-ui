import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

String? _guardado;

/// A aparência da vitrine é a mesma peça dos apps (v1.3): tema, preto total, cores e
/// densidade. Guarda só na memória (a vitrine abre sempre no claro, violeta, padrão).
final aparencia = SsAppearanceController(
  brand: SsBrand.violeta,
  initial: const SsAppearance(themeMode: ThemeMode.light),
  read: () async => _guardado,
  write: (v) async => _guardado = v,
);

/// Abre o [SsAppearancePanel] numa folha.
Future<void> abrirAparencia(BuildContext context) => showSsSheet<void>(
  context,
  title: 'Aparência',
  subtitle: 'Tema, preto total, cores e densidade.',
  icon: Icons.palette_outlined,
  child: SsAppearancePanel(controller: aparencia),
);

/// Atalhos de aparência: claro/escuro, densidade em ciclo e o painel completo.
class AparenciaBar extends StatelessWidget {
  const AparenciaBar({super.key, this.densidade = true});

  /// Mostra o atalho da densidade (nas barras das páginas fica só no painel, para o título caber).
  final bool densidade;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: aparencia,
    builder: (context, _) {
      final v = aparencia.value;
      final escuro = Theme.of(context).brightness == Brightness.dark;
      final i = SsDensity.values.indexOf(v.density);
      final proxima = SsDensity.values[(i + 1) % SsDensity.values.length];
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (densidade)
            SsIconButton(
              icon: v.density.isCompact
                  ? Icons.density_small_rounded
                  : (v.density.isComfortable ? Icons.density_large_rounded : Icons.density_medium_rounded),
              tooltip: 'Densidade: ${_densidade(v.density)}',
              onPressed: () => aparencia.set(v.copyWith(density: proxima)),
            ),
          SsIconButton(
            icon: escuro ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: escuro ? 'Claro' : 'Escuro',
            onPressed: () => aparencia.set(v.copyWith(themeMode: escuro ? ThemeMode.light : ThemeMode.dark)),
          ),
          SsIconButton(icon: Icons.palette_outlined, tooltip: 'Aparência', onPressed: () => abrirAparencia(context)),
        ],
      );
    },
  );
}

String _densidade(SsDensity d) => d.isCompact ? 'compacta' : (d.isComfortable ? 'confortável' : 'padrão');
