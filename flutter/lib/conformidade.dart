/// Conformidade de um app da suíte com o componentes_ui: tudo o que tem peça no
/// pacote usa a peça do pacote. Feito para rodar num teste do app (e portanto na
/// CI), sem lista de exceções:
///
/// ```dart
/// import 'dart:io';
/// import 'package:componentes_ui/conformidade.dart';
/// import 'package:flutter_test/flutter_test.dart';
///
/// void main() {
///   test('100% componentes_ui', () {
///     final problemas = conferirConformidade(Directory.current);
///     expect(problemas, isEmpty, reason: problemas.join('\n'));
///   });
/// }
/// ```
///
/// O que reprova (em `lib/` inteira):
/// 1. `componentes_ui` no pubspec fora de git + `ref:` de tag (`vX.Y.Z`), ou com `path:`;
/// 2. widgets e funções do Material/Cupertino que têm equivalente `Ss*`;
/// 3. cor literal (`Colors.*`, `Color(0x…)`, `Color.fromARGB/fromRGBO`);
/// 4. tipografia literal (`fontSize:`/`letterSpacing:` com número, `fontFamily:` com
///    texto, `height:`/`wordSpacing:` com número dentro de `TextStyle(...)`/`copyWith(...)`);
/// 5. gráfico fora do pacote (`fl_chart` no pubspec ou importado);
/// 6. (v0.19.1) card à mão: `BoxDecoration` com a cor `surface` e a sombra de card
///    (`AppShadows.card`, ou `boxShadow:` com o raio `AppRadius.card`/`cardActive`),
///    que é o `SsCard` (ou `SsCard(soft:)`). Para não pegar desenho de domínio, fica
///    de fora decoração com `gradient:`, `image:` ou `shape:` (círculo), cor que não
///    é a `surface` pura (o papel do cupom, `surface.withValues`, ternário) e o
///    `ShapeDecoration`.
///
/// v0.19.1: a chamada com tipo (`showDialog<void>(`, `PopupMenuButton<String>(`)
/// também conta (antes passava).
///
/// Fica de fora o que o pacote não substitui: `Scaffold`, `InkWell`, `Material`,
/// layout (`Row`, `Column`, `Padding`…), `RawAutocomplete` etc.
library;

import 'dart:io';

/// Um problema encontrado: arquivo (relativo à raiz), linha e o trecho.
class Violacao {
  const Violacao(this.regra, this.arquivo, this.linha, this.trecho);

  final String regra;
  final String arquivo;
  final int linha;
  final String trecho;

  @override
  String toString() => '$arquivo:$linha [$regra] $trecho';
}

/// Widgets e funções do Material/Cupertino que têm par no pacote.
const proibidosMaterial = <String>[
  'AppBar', 'SliverAppBar', 'TextButton', 'ElevatedButton', 'OutlinedButton', 'FilledButton', 'IconButton', //
  'FloatingActionButton', 'AlertDialog', 'SimpleDialog', 'Dialog', 'showDialog', 'showGeneralDialog',
  'showModalBottomSheet', 'BottomSheet', 'showBottomSheet', 'SnackBar', 'showSnackBar', 'MaterialBanner',
  'CircularProgressIndicator', 'LinearProgressIndicator', 'RefreshProgressIndicator', 'RefreshIndicator',
  'Card', 'ListTile', 'SwitchListTile', 'CheckboxListTile', 'RadioListTile', 'ExpansionTile',
  'Chip', 'FilterChip', 'ChoiceChip', 'ActionChip', 'InputChip', 'RawChip',
  'Switch', 'Checkbox', 'Radio', 'Slider', 'RangeSlider', 'ToggleButtons', 'SegmentedButton',
  'TextField', 'TextFormField', 'DropdownButton', 'DropdownButtonFormField', 'DropdownMenu', 'DropdownMenuItem',
  'Divider', 'VerticalDivider', 'TabBar', 'TabBarView', 'NavigationBar', 'BottomNavigationBar', 'NavigationRail',
  'Drawer', 'Tooltip', 'PopupMenuButton', 'PopupMenuItem', 'showMenu', 'MenuAnchor', 'showDatePicker',
  'showTimePicker', 'DataTable', 'Badge', 'SearchBar', 'showSearch', 'Stepper',
];

List<Violacao> conferirConformidade(Directory raiz) {
  final problemas = <Violacao>[];
  final sep = Platform.pathSeparator;
  String rel(File f) => f.path.substring(raiz.path.length).replaceFirst(RegExp('^[/\\\\]'), '');

  // 1 e 5 (pubspec)
  final pubspec = File('${raiz.path}${sep}pubspec.yaml');
  final pub = pubspec.existsSync() ? pubspec.readAsStringSync() : '';
  final bloco = RegExp(r'^  componentes_ui:\n((?:    .*\n)+)', multiLine: true).firstMatch(pub)?.group(1) ?? '';
  final tagOk =
      RegExp(r'^\s+git:', multiLine: true).hasMatch(bloco) &&
      RegExp(r'^\s+ref:\s*v\d+\.\d+\.\d+\s*$', multiLine: true).hasMatch(bloco) &&
      !RegExp(r'^    path:', multiLine: true).hasMatch(bloco);
  if (!tagOk) {
    problemas.add(const Violacao('pubspec', 'pubspec.yaml', 0, 'componentes_ui precisa vir por git + ref: vX.Y.Z'));
  }
  final linhasPub = pub.split('\n');
  for (var i = 0; i < linhasPub.length; i++) {
    if (RegExp(r'^\s+fl_chart:').hasMatch(linhasPub[i])) {
      problemas.add(Violacao('gráfico', 'pubspec.yaml', i + 1, 'fl_chart: use os gráficos Ss*'));
    }
  }

  final lib = Directory('${raiz.path}${sep}lib');
  if (!lib.existsSync()) return problemas;
  final arquivos = lib.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final material = RegExp('(?<![A-Za-z_0-9])(${proibidosMaterial.join('|')})(\\.\\w+)?(<[\\w<>?, ]*>)?\\(');
  final regras = <String, RegExp>{
    'cupertino': RegExp(r'(?<![A-Za-z_0-9])(Cupertino\w+|showCupertino\w+)\(|package:flutter/cupertino\.dart'),
    'scaffold-messenger': RegExp(r'(?<![A-Za-z_0-9])ScaffoldMessenger\b'),
    'cor': RegExp(
      r'(?<![A-Za-z_0-9])(Colors|CupertinoColors)\.\w+|(?<![A-Za-z_0-9])Color\(\s*(0x|\d)|'
      r'Color\.(fromARGB|fromRGBO)\(',
    ),
    'tipografia': RegExp(r'''fontSize:\s*[\d.]+|letterSpacing:\s*-?[\d.]+|fontFamily:\s*['"]'''),
    'gráfico': RegExp(r'package:fl_chart/'),
  };

  for (final f in arquivos) {
    final texto = f.readAsStringSync();
    final linhas = texto.split('\n');
    for (var i = 0; i < linhas.length; i++) {
      final l = linhas[i];
      if (l.trimLeft().startsWith('//')) continue; // comentário e doc não contam
      for (final m in material.allMatches(l)) {
        problemas.add(Violacao('material:${m.group(1)}', rel(f), i + 1, l.trim()));
      }
      for (final r in regras.entries) {
        if (r.value.hasMatch(l)) problemas.add(Violacao(r.key, rel(f), i + 1, l.trim()));
      }
    }
    // height/wordSpacing literal dentro de TextStyle(...) e .copyWith(...)
    for (final abre in RegExp(r'(TextStyle\(|\.copyWith\()').allMatches(texto)) {
      final ini = abre.end - 1;
      var nivel = 0;
      var fim = ini;
      for (; fim < texto.length; fim++) {
        if (texto[fim] == '(') nivel++;
        if (texto[fim] == ')' && --nivel == 0) break;
      }
      final corpo = texto.substring(ini, fim);
      for (final k in RegExp(r'\b(height|wordSpacing):\s*-?[\d.]+').allMatches(corpo)) {
        final linha = '\n'.allMatches(texto.substring(0, ini + k.start)).length + 1;
        problemas.add(Violacao('tipografia', rel(f), linha, linhas[linha - 1].trim()));
      }
    }
    // 6: card à mão (BoxDecoration com surface + sombra de card).
    for (final abre in RegExp(r'(?<![A-Za-z_0-9])BoxDecoration\(').allMatches(texto)) {
      final corpo = _corpo(texto, abre.end - 1);
      if (_cardAMao(corpo)) {
        final linha = '\n'.allMatches(texto.substring(0, abre.start)).length + 1;
        if (linhas[linha - 1].trimLeft().startsWith('//')) continue;
        problemas.add(Violacao('card-à-mão:SsCard', rel(f), linha, linhas[linha - 1].trim()));
      }
    }
  }
  return problemas;
}

/// O texto entre o `(` em [ini] e o `)` que fecha (sem ele).
String _corpo(String texto, int ini) {
  var nivel = 0;
  var fim = ini;
  for (; fim < texto.length; fim++) {
    if (texto[fim] == '(') nivel++;
    if (texto[fim] == ')' && --nivel == 0) break;
  }
  return texto.substring(ini, fim);
}

final _corSurface = RegExp(r'(?<![\w])color:\s*(?:[A-Za-z_]\w*(?:\([^()]*\))?\.)*surface\s*(?:,|\)|$)');
final _sombraCard = RegExp(r'AppShadows\.card\b');
final _raioCard = RegExp(r'AppRadius\.(card|cardActive)\b');
final _dominio = RegExp(r'(?<![\w])(gradient|image|shape):');

/// Card à mão: a cor é a `surface` pura e a sombra é a do card (o token, ou
/// qualquer `boxShadow:` com o raio de card); fora o que é desenho de domínio.
bool _cardAMao(String corpo) {
  if (_dominio.hasMatch(corpo) || !_corSurface.hasMatch(corpo)) return false;
  return _sombraCard.hasMatch(corpo) || (corpo.contains('boxShadow:') && _raioCard.hasMatch(corpo));
}
