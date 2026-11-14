import 'dart:io';

import 'package:componentes_ui/conformidade.dart';
import 'package:flutter_test/flutter_test.dart';

Directory _app({required String pubspec, required Map<String, String> arquivos}) {
  final raiz = Directory.systemTemp.createTempSync('conformidade_');
  File('${raiz.path}/pubspec.yaml').writeAsStringSync(pubspec);
  arquivos.forEach((nome, texto) {
    final f = File('${raiz.path}/lib/$nome')..createSync(recursive: true);
    f.writeAsStringSync(texto);
  });
  return raiz;
}

const _pubOk = '''
name: app
dependencies:
  componentes_ui:
    git:
      url: https://github.com/minhasuite/componentes-ui.git
      path: flutter
      ref: v0.19.0
''';

void main() {
  test('app limpo passa', () {
    final raiz = _app(
      pubspec: _pubOk,
      arquivos: {
        'tela.dart': '''
// Comentário pode citar AppBar( e Colors.red sem reprovar.
Widget build(c) => Scaffold(appBar: SsTopBar(title: 'x'), body: SsButton(label: 'ok', onPressed: () {}));
final estilo = TextStyle(color: SsColors.of(c).ink, fontSize: AppType.meta, height: AppType.leading);
''',
      },
    );
    expect(conferirConformidade(raiz), isEmpty);
  });

  test('reprova cada regra', () {
    final raiz = _app(
      pubspec: '''
name: app
dependencies:
  componentes_ui:
    path: ../componentes-ui/flutter
  fl_chart: ^1.0.0
''',
      arquivos: {
        'tela.dart': '''
import 'package:fl_chart/fl_chart.dart';
Widget build(c) => Scaffold(appBar: AppBar(title: Text('x')), body: TextButton(onPressed: null, child: Text('y')));
final cor = Colors.red;
final outra = Color(0xFF000000);
final t = TextStyle(fontSize: 14, height: 1.2);
void avisa(c) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('z')));
''',
      },
    );
    final regras = conferirConformidade(raiz).map((v) => v.regra).toSet();
    expect(
      regras,
      containsAll(<String>[
        'pubspec',
        'gráfico',
        'material:AppBar',
        'material:TextButton',
        'material:SnackBar',
        'scaffold-messenger',
        'cor',
        'tipografia',
      ]),
    );
  });

  test('v0.19.1: chamada com tipo também reprova', () {
    final raiz = _app(
      pubspec: _pubOk,
      arquivos: {
        'tela.dart': '''
void abre(c) => showDialog<void>(context: c, builder: (_) => Text('x'));
final menu = PopupMenuButton<Map<String, int>>(itemBuilder: (_) => []);
''',
      },
    );
    final regras = conferirConformidade(raiz).map((v) => v.regra).toList();
    expect(regras, containsAll(<String>['material:showDialog', 'material:PopupMenuButton']));
  });

  test('v0.23.2: chamada com tipo record também reprova', () {
    final raiz = _app(
      pubspec: _pubOk,
      arquivos: {
        'tela.dart': '''
Future<void> abre(c) => showDialog<({String kind, String body})>(context: c, builder: (_) => Text('x'));
Future<void> folha(c) => showModalBottomSheet<(int, String)?>(context: c, builder: (_) => Text('x'));
''',
      },
    );
    final regras = conferirConformidade(raiz).map((v) => v.regra).toList();
    expect(regras, containsAll(<String>['material:showDialog', 'material:showModalBottomSheet']));
  });

  test('v0.19.1: peças novas passam (tooltip, abas, fio em pé, cor de dado, glifo, transparente)', () {
    final raiz = _app(
      pubspec: _pubOk,
      arquivos: {
        'tela.dart': '''
Widget build(c) => Row(children: [
  SsTooltip(message: 'x', child: SsTabsView(controller: t, children: [])),
  SsDivider.vertical(),
  SsDivider(vertical: true),
  StoreIcon(color: ssColorFromHex('#E43225')),
  Box(color: ssColorFromRgb(0x3A6EA5), border: selected ? c.accent : AppColors.transparent),
]);
final estilo = TextStyle(fontSize: AppType.micro, height: AppType.tight, letterSpacing: AppType.trackingTight);
final glifo = ssIconTextStyle(icon, size: AppType.headerTitle, color: cor);
void abre(c) => showSsFullscreen<void>(c, title: 'Frase', child: Text('x'));
''',
      },
    );
    expect(conferirConformidade(raiz), isEmpty);
  });

  group('v0.19.1: card à mão', () {
    List<Violacao> confere(String codigo) => conferirConformidade(
      _app(pubspec: _pubOk, arquivos: {'tela.dart': codigo}),
    ).where((v) => v.regra == 'card-à-mão:SsCard').toList();

    test('surface + AppShadows.card reprova, com a linha do BoxDecoration', () {
      final v = confere('''
Widget build(c) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: c.surface,
    borderRadius: BorderRadius.circular(AppRadius.card),
    boxShadow: AppShadows.card,
  ),
);
''');
      expect(v, hasLength(1));
      expect(v.single.linha, 3);
    });

    test('numa linha só e com SsColors.of(context).surface', () {
      expect(
        confere(
          'final d = BoxDecoration(color: SsColors.of(context).surface, borderRadius: r, boxShadow: AppShadows.card);',
        ),
        hasLength(1),
      );
    });

    test('surface + boxShadow próprio + raio de card reprova', () {
      expect(
        confere('''
final d = BoxDecoration(
  color: c.surface,
  borderRadius: BorderRadius.circular(AppRadius.cardActive),
  boxShadow: c.activeShadow,
);
'''),
        hasLength(1),
      );
    });

    test('desenho de domínio passa', () {
      expect(
        confere('''
// papel do cupom, círculo, gradiente, foto, transparência, ternário e ShapeDecoration
final a = BoxDecoration(color: c.paper, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card);
final b = BoxDecoration(color: c.surface, shape: BoxShape.circle, boxShadow: AppShadows.card);
final g = BoxDecoration(color: c.surface, gradient: grad, boxShadow: AppShadows.card);
final i = BoxDecoration(color: c.surface, image: foto, boxShadow: AppShadows.card);
final t = BoxDecoration(color: c.surface.withValues(alpha: .6), boxShadow: AppShadows.card);
final u = BoxDecoration(color: lido ? c.surface : c.field, boxShadow: AppShadows.card);
final s = ShapeDecoration(shape: forma, color: c.surface, shadows: AppShadows.card);
// barra de baixo: surface com sombra, mas sem raio de card
final n = BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line)), boxShadow: sombra);
// campo sem sombra
final f = BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.card));
'''),
        isEmpty,
      );
    });
  });
}
