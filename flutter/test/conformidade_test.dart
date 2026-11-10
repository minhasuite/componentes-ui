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
}
