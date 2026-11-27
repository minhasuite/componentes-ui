// v1.14.0 "interface e animação": os textos das peças novas (gráfico que se arrasta, período × anterior, linha que
// se expande, folha com 3 alturas, check de sucesso e seleção). As mesmas chaves, em snake_case, estão no
// `componentes_ui.interface.*` da gem. O idioma segue o do [SsStrings].
import 'package:material_ui/material_ui.dart';

import '../ss_strings.dart';

/// Textos da v1.14: `SsInterfaceStrings.of(context)` (pt, en ou es pelo idioma do [SsStrings]). Moldes com `%{x}`
/// passam pelo [fill].
class SsInterfaceStrings {
  const SsInterfaceStrings({
    required this.scrubHint,
    required this.periodCurrent,
    required this.periodPrevious,
    required this.periodVs,
    required this.periodSummary,
    required this.periodChoose,
    required this.expandEdit,
    required this.expandLabel,
    required this.expandSave,
    required this.expandCancel,
    required this.expandSaved,
    required this.sheetHandle,
    required this.sheetHint,
    required this.sheetExpand,
    required this.sheetCollapse,
    required this.sheetSize,
    required this.success,
    required this.selectionRangeHint,
  });

  final String scrubHint;
  final String periodCurrent;
  final String periodPrevious;
  final String periodVs;
  final String periodSummary;
  final String periodChoose;
  final String expandEdit;
  final String expandLabel;
  final String expandSave;
  final String expandCancel;
  final String expandSaved;
  final String sheetHandle;
  final String sheetHint;
  final String sheetExpand;
  final String sheetCollapse;
  final String sheetSize;
  final String success;
  final String selectionRangeHint;

  /// Todos os textos por chave (a mesma ordem da gem), para o teste comparar os moldes.
  Map<String, String> get all => {
    'scrubHint': scrubHint,
    'periodCurrent': periodCurrent,
    'periodPrevious': periodPrevious,
    'periodVs': periodVs,
    'periodSummary': periodSummary,
    'periodChoose': periodChoose,
    'expandEdit': expandEdit,
    'expandLabel': expandLabel,
    'expandSave': expandSave,
    'expandCancel': expandCancel,
    'expandSaved': expandSaved,
    'sheetHandle': sheetHandle,
    'sheetHint': sheetHint,
    'sheetExpand': sheetExpand,
    'sheetCollapse': sheetCollapse,
    'sheetSize': sheetSize,
    'success': success,
    'selectionRangeHint': selectionRangeHint,
  };

  /// O texto com %{x} trocado pelos valores.
  static String fill(String template, Map<String, Object> values) =>
      template.replaceAllMapped(RegExp(r'%\{(\w+)\}'), (m) => '${values[m.group(1)] ?? ''}');

  static SsInterfaceStrings of(BuildContext context) => forLocale(SsStrings.of(context).locale);

  static SsInterfaceStrings forLocale(Locale l) => switch (l.languageCode) {
    'en' => en,
    'es' => es,
    _ => pt,
  };

  static const pt = SsInterfaceStrings(
    scrubHint: 'Arraste para ver cada ponto',
    periodCurrent: 'Este período',
    periodPrevious: 'Período anterior',
    periodVs: 'em relação ao período anterior',
    periodSummary: '%{current} neste período, %{previous} no anterior',
    periodChoose: 'Período',
    expandEdit: 'Editar',
    expandLabel: 'Editar %{title}',
    expandSave: 'Salvar',
    expandCancel: 'Cancelar',
    expandSaved: 'Salvo',
    sheetHandle: 'Alça da folha',
    sheetHint: 'Arraste para mudar a altura',
    sheetExpand: 'Expandir',
    sheetCollapse: 'Recolher',
    sheetSize: '%{percent}% da tela',
    success: 'Concluído',
    selectionRangeHint: 'Shift + clique marca o intervalo',
  );

  static const en = SsInterfaceStrings(
    scrubHint: 'Drag to see each point',
    periodCurrent: 'This period',
    periodPrevious: 'Previous period',
    periodVs: 'vs. previous period',
    periodSummary: '%{current} this period, %{previous} in the previous one',
    periodChoose: 'Period',
    expandEdit: 'Edit',
    expandLabel: 'Edit %{title}',
    expandSave: 'Save',
    expandCancel: 'Cancel',
    expandSaved: 'Saved',
    sheetHandle: 'Sheet handle',
    sheetHint: 'Drag to change the height',
    sheetExpand: 'Expand',
    sheetCollapse: 'Collapse',
    sheetSize: '%{percent}% of the screen',
    success: 'Done',
    selectionRangeHint: 'Shift + click selects a range',
  );

  static const es = SsInterfaceStrings(
    scrubHint: 'Arrastra para ver cada punto',
    periodCurrent: 'Este período',
    periodPrevious: 'Período anterior',
    periodVs: 'frente al período anterior',
    periodSummary: '%{current} en este período, %{previous} en el anterior',
    periodChoose: 'Período',
    expandEdit: 'Editar',
    expandLabel: 'Editar %{title}',
    expandSave: 'Guardar',
    expandCancel: 'Cancelar',
    expandSaved: 'Guardado',
    sheetHandle: 'Asa de la hoja',
    sheetHint: 'Arrastra para cambiar la altura',
    sheetExpand: 'Expandir',
    sheetCollapse: 'Contraer',
    sheetSize: '%{percent}% de la pantalla',
    success: 'Listo',
    selectionRangeHint: 'Mayús + clic marca el intervalo',
  );
}
