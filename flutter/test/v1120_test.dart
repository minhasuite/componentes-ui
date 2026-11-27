// v1.12.0 "Kit Brasil": as contas (SsBr, SsBoleto, SsNfeKey, SsPixCode), o QR puro-Dart (a mesma matriz da gem), o
// colar inteligente (SsPasteDetector contra os exemplos de docs/v1120/exemplos.json, os mesmos do Ruby e do JS), os
// formatadores do SsFormats e as peças SsPixCard, SsNfeCard, SsSmartPaste, SsPixKeyField, SsBoletoField, SsCepField e
// SsDocumentField, com o ssA11yAudit.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _ex = jsonDecode(File('../docs/v1120/exemplos.json').readAsStringSync()) as Map<String, dynamic>;
final _hoje = DateTime.parse(_ex['today'] as String);

Widget _app(Widget child, {SsDensity density = SsDensity.standard, Locale locale = const Locale('pt', 'BR')}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light, density: density),
      locale: locale,
      supportedLocales: SsStrings.supportedLocales,
      localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
      home: Scaffold(
        body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
      ),
    );

Future<void> _pump(WidgetTester t, Widget w, {SsDensity density = SsDensity.standard, Locale? locale}) async {
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(_app(w, density: density, locale: locale ?? const Locale('pt', 'BR')));
  await t.pump();
}

String _cpf(String base) {
  var s = base;
  for (var k = 0; k < 2; k++) {
    var sum = 0;
    for (var i = 0; i < s.length; i++) {
      sum += int.parse(s[i]) * (s.length + 1 - i);
    }
    final r = sum % 11;
    s += '${r < 2 ? 0 : 11 - r}';
  }
  return s;
}

String _flip(String s, int i) => '${s.substring(0, i)}${(int.parse(s[i]) + 1) % 10}${s.substring(i + 1)}';

final _pix = SsPixCode.build(key: 'loja@exemplo.com.br', name: 'Loja Exemplo', city: 'São Paulo', amountCents: 12345);
const _linha = '34191.09008 00012.345674 89012.345677 1 16560000012345';

/// Guarda o que foi copiado e responde ao "colar".
String? _clip;
void _mockClipboard(WidgetTester t) {
  _clip = null;
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') _clip = (call.arguments as Map)['text'] as String;
    if (call.method == 'Clipboard.getData') return {'text': _clip};
    return null;
  });
}

void main() {
  group('contas', () {
    test('CPF: 300 gerados com DV são válidos; um dígito trocado ou todos iguais, não', () {
      final rng = Random(1120);
      for (var n = 0; n < 300; n++) {
        final c = _cpf(List.generate(9, (_) => rng.nextInt(10)).join());
        if (RegExp(r'^(\d)\1{10}$').hasMatch(c)) continue;
        expect(SsBr.cpfValid(c), isTrue, reason: c);
        expect(SsBr.cpfValid(SsBr.formatCpf(c)), isTrue);
        expect(SsBr.cpfValid(_flip(c, 10)), isFalse, reason: c);
      }
      expect(SsBr.cpfValid('111.111.111-11'), isFalse);
      expect(SsBr.formatCpf('60472'), '604.72');
    });

    test('CNPJ numérico e alfanumérico (2026): DV com ASCII − 48', () {
      final rng = Random(7);
      const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      for (var n = 0; n < 300; n++) {
        final base = List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
        final j = base + SsBr.cnpjDv(base);
        expect(SsBr.cnpjValid(j), isTrue, reason: j);
        expect(SsBr.cnpjValid(SsBr.formatCnpj(j).toLowerCase()), isTrue, reason: j);
        expect(SsBr.cnpjValid(_flip(j, 13)), isFalse, reason: j);
      }
      expect(SsBr.cnpjValid('12.ABC.345/01DE-35'), isTrue);
      expect(SsBr.documentKind('12ABC'), 'cnpj');
      expect(SsBr.documentKind('123.456'), 'cpf');
    });

    test('boleto bancário: fator novo (22/02/2025), DVs, valor e vencimento; 50 gerados', () {
      final venc = DateTime.utc(2026, 12, 10);
      final fator = SsBoleto.factor(venc);
      expect(SsBoleto.due('$fator', today: _hoje), venc);
      expect(SsBoleto.due('1000', today: _hoje), DateTime.utc(2025, 2, 22));
      expect(SsBoleto.due('9999', today: _hoje), DateTime.utc(2025, 2, 21));
      expect(SsBoleto.due('0000'), isNull);
      final rng = Random(3);
      for (var n = 0; n < 50; n++) {
        final bank = ['001', '033', '104', '237', '341', '748'][rng.nextInt(6)];
        final valor = (rng.nextInt(9999998) + 1).toString().padLeft(10, '0');
        final livre = List.generate(25, (_) => rng.nextInt(10)).join();
        final code = '${bank}9${SsBr.mod11Bank('${bank}9$fator$valor$livre')}$fator$valor$livre';
        final line = SsBr.boletoLineFromBarcode(code)!;
        final b = SsBoleto.parse(line, today: _hoje)!;
        expect(b.valid, isTrue, reason: line);
        expect(b.barcode, code);
        expect(b.amountCents, int.parse(valor));
        expect(b.dueDate, venc);
        expect(SsBoleto.parse(_flip(line, 2), today: _hoje)!.errors, contains('field_dv'));
      }
    });

    test('boleto de arrecadação: mod 10 (6/7) e mod 11 (8/9), segmento e valor', () {
      final rng = Random(5);
      for (final id in ['6', '7', '8', '9']) {
        for (var n = 0; n < 20; n++) {
          final seg = ['1', '2', '3', '4', '5', '6', '7', '9'][rng.nextInt(8)];
          final resto = List.generate(40, (_) => rng.nextInt(10)).join();
          final sem = '8$seg$id$resto';
          final dv = id == '6' || id == '7' ? SsBr.mod10(sem) : SsBr.mod11Dv(sem);
          final line = SsBr.boletoLineFromBarcode('8$seg$id$dv$resto')!;
          final b = SsBoleto.parse(line)!;
          expect(b.valid, isTrue, reason: line);
          expect(b.kind, SsBoletoKind.collection);
          expect(b.segment, SsBr.segments[seg]);
          final v = int.parse(resto.substring(0, 11));
          expect(b.amountCents, id == '6' || id == '8' ? (v == 0 ? null : v) : null);
          expect(SsBoleto.parse(_flip(line, 5))!.valid, isFalse);
        }
      }
    });

    test('chave de acesso: DV, UF, modelo; 11 blocos de 4', () {
      final rng = Random(11);
      final ufs = SsBr.ufs.keys.toList();
      for (var n = 0; n < 100; n++) {
        final k43 =
            '${ufs[rng.nextInt(ufs.length)]}26${(rng.nextInt(12) + 1).toString().padLeft(2, '0')}'
            '${List.generate(14, (_) => rng.nextInt(10)).join()}${['55', '65', '57'][rng.nextInt(3)]}'
            '${List.generate(21, (_) => rng.nextInt(10)).join()}';
        final key = '$k43${SsNfeKey.dvFor(k43)}';
        final k = SsNfeKey.parse(key)!;
        expect(k.valid, isTrue, reason: key);
        expect(k.display.split(' '), hasLength(11));
        expect(SsNfeKey.parse(_flip(key, 43))!.valid, isFalse);
      }
      expect(SsNfeKey.parse('123'), isNull);
    });

    test('Pix: CRC16, montar e ler (o mesmo do Ruby), tipo e chave normalizada', () {
      expect(SsPixCode.crc16('123456789'), '29B1');
      final code = SsPixCode.build(
        key: 'loja@exemplo.com.br',
        name: 'Loja São João',
        city: 'São Paulo',
        amountCents: 12345,
        txid: 'PED1',
      );
      final p = SsPixCode.parse(code)!;
      expect(p.valid, isTrue);
      expect(p.amountCents, 12345);
      expect(p.name, 'LOJA SAO JOAO');
      expect(p.city, 'SAO PAULO');
      expect(p.keyType, SsPixKeyType.email);
      expect(p.txid, 'PED1');
      // O mesmo copia e cola que o Br.pix_build da gem gerou para o exemplo 1.
      final ex1 = (_ex['exemplos'] as List).first as Map;
      expect(
        SsPixCode.build(
          key: 'loja@exemplo.com.br',
          name: 'Loja Exemplo',
          city: 'São Paulo',
          amountCents: 12345,
          txid: 'PEDIDO1042',
        ),
        ex1['input'],
      );
      expect(SsPixCode.parse('${code.substring(0, code.length - 4)}0000')!.valid, code.endsWith('0000'));
      expect(SsPixCode.parse('qualquer coisa'), isNull);
      final tipos = {
        '604.721.385-53': SsPixKeyType.cpf,
        '11.222.333/0001-81': SsPixKeyType.cnpj,
        '+55 11 98765-4321': SsPixKeyType.phone,
        '(11) 98765-4321': SsPixKeyType.phone,
        'x@exemplo.com': SsPixKeyType.email,
        '123e4567-e89b-42d3-a456-426614174000': SsPixKeyType.random,
        'abc': null,
        '123': null,
      };
      tipos.forEach((k, v) => expect(SsBr.pixKeyType(k), v, reason: k));
      expect(SsBr.pixKeyNormalize('(11) 98765-4321'), '+5511987654321');
    });

    test('formatadores do SsFormats (os ss_* da gem)', () {
      const f = SsFormats.brl;
      expect(f.cpf('60472138553'), '604.721.385-53');
      expect(f.cnpj('12abc34501de35'), '12.ABC.345/01DE-35');
      expect(f.cep('01310100'), '01310-100');
      expect(f.phoneBr('11987654321'), '(11) 98765-4321');
      expect(f.phoneBr('+5511987654321'), '+55 (11) 98765-4321');
      expect(f.phoneBr('2134567890'), '(21) 3456-7890');
      expect(f.boleto('34191090080001234567489012345677116560000012345'), _linha);
      expect(
        f.boleto('836900000016234500481234456789012345567890123456'),
        '83690000001-6 23450048123-4 45678901234-5 56789012345-6',
      );
      expect(f.nfeKey('1' * 44).split(' '), hasLength(11));
    });
  });

  group('QR (SsQrCode)', () {
    test('a mesma matriz do ComponentesUi::Qr, módulo a módulo', () {
      for (final q in (_ex['qr'] as List).cast<Map>()) {
        final c = SsQrCode.encode(q['text'] as String);
        final rows = [for (final r in c.rows) r.map((b) => b ? '1' : '0').join()];
        expect(rows, q['rows'], reason: (q['text'] as String).substring(0, 5));
      }
      expect(SsQrCode.encode('x' * 2300).size, 177);
      expect(() => SsQrCode.encode('x' * 3000), throwsArgumentError);
    });
  });

  group('colar inteligente (SsPasteDetector)', () {
    test('os exemplos de docs/v1120/exemplos.json dão o mesmo que no Ruby e no JS', () {
      final exemplos = (_ex['exemplos'] as List).cast<Map<String, dynamic>>();
      expect(exemplos.length, greaterThanOrEqualTo(50));
      for (final e in exemplos) {
        final m = SsPasteDetector.detect(e['input'] as String, today: _hoje)!;
        final why = jsonEncode(e['input']);
        expect(m.type.key, e['type'], reason: why);
        expect(m.valid, e['valid'], reason: why);
        expect(m.value, e['value'], reason: why);
        expect(m.also.map((a) => a.key).toList(), e['also'], reason: why);
        expect(m.fields, e['fields'], reason: why);
      }
      expect({for (final e in exemplos) e['type']}, {for (final t in SsPasteType.values) t.key});
      expect(SsPasteDetector.detect('  '), isNull);
    });

    test('a frase do cartão em pt, en e es', () {
      final b = SsPasteDetector.detect(_linha, today: _hoje)!;
      expect(SsPasteDetector.summary(b), 'Isso parece um boleto de R\$ 123,45 com vencimento em 10/12/2026');
      expect(
        SsPasteDetector.summary(b, br: SsBrStrings.en, strings: SsStrings.en),
        startsWith('This looks like a boleto of'),
      );
      expect(
        SsPasteDetector.summary(b, br: SsBrStrings.es, strings: SsStrings.es),
        startsWith('Esto parece un boleto de'),
      );
      expect(
        SsPasteDetector.summary(SsPasteDetector.detect('123.456.789-00')!),
        'Parece um CPF, mas os números não conferem.',
      );
      expect(SsPasteDetector.summary(SsPasteDetector.detect('oi oi')!), 'Texto livre, 5 caracteres');
    });

    test('textos: pt, en e es com as mesmas chaves e nada vazio', () {
      for (final s in [SsBrStrings.pt, SsBrStrings.en, SsBrStrings.es]) {
        expect(s.pasteSummary.keys.toSet(), SsBrStrings.pt.pasteSummary.keys.toSet());
        expect(s.pasteWhat.keys.toSet(), SsBrStrings.pt.pasteWhat.keys.toSet());
        expect(s.keyTypes.keys.toSet(), {'cpf', 'cnpj', 'phone', 'email', 'random'});
        expect(s.nfeStatus.keys.toSet(), {for (final v in SsNfeStatus.values) v.name});
        expect([...s.pasteSummary.values, s.pixCopy, s.boletoScan].every((v) => v.trim().isNotEmpty), isTrue);
      }
      expect(SsBrStrings.en.pixCopy, 'Copy code');
      expect(SsBrStrings.es.pixCopy, 'Copiar código');
    });
  });

  group('SsPixCard', () {
    testWidgets('lê valor e recebedor do código, copia com retorno e o QR tem nome', (t) async {
      _mockClipboard(t);
      var copiou = 0;
      await _pump(t, SsPixCard(code: _pix, onCopy: () => copiou++));
      expect(find.text('R\$ 123,45'), findsOneWidget);
      expect(find.text('Recebedor: LOJA EXEMPLO'), findsOneWidget);
      expect(find.text('Aguardando pagamento'), findsOneWidget);
      expect(find.bySemanticsLabel('QR Code do Pix'), findsOneWidget);
      expect(find.byType(SsQrImage), findsOneWidget);
      await ssA11yAudit(t);
      await t.tap(find.text('Copiar código'));
      await t.pump();
      expect(_clip, _pix);
      expect(copiou, 1);
      expect(find.text('Código copiado'), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      expect(find.text('Copiar código'), findsOneWidget);
    });

    testWidgets('contagem regressiva; ao zerar vira expirado e chama onExpired', (t) async {
      var agora = DateTime(2026, 11, 27, 10);
      var expirou = 0;
      await _pump(
        t,
        SsPixCard(
          code: _pix,
          expiresAt: DateTime(2026, 11, 27, 10, 0, 3),
          now: () => agora,
          onExpired: () => expirou++,
          onRegenerate: () {},
        ),
      );
      expect(find.text('Vale por 00:03'), findsOneWidget);
      agora = agora.add(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Vale por 00:02'), findsOneWidget);
      agora = agora.add(const Duration(seconds: 2));
      await t.pump(const Duration(seconds: 1));
      await t.pump(SsMotion.medium);
      expect(expirou, 1);
      expect(find.text('Código expirado'), findsOneWidget);
      expect(find.text('Gerar outro código'), findsOneWidget);
      expect(find.text('Copiar código'), findsNothing);
      await ssA11yAudit(t);
    });

    testWidgets('pago: o ✓ e o texto; sem valor, "Valor livre"; en', (t) async {
      await _pump(t, SsPixCard(code: _pix, status: SsPixStatus.paid));
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Pagamento recebido'), findsOneWidget);
      expect(find.text('Pronto, o Pix caiu.'), findsOneWidget);
      final livre = SsPixCode.build(key: '+5511987654321', name: 'Ana', city: 'Recife');
      await _pump(t, SsPixCard(code: livre), locale: const Locale('en'));
      expect(find.text('Any amount'), findsOneWidget);
      expect(find.text('Copy code'), findsOneWidget);
    });
  });

  group('SsNfeCard', () {
    const k43 = '3526111122233300018165002000000789187654321';
    final key = '$k43${SsNfeKey.dvFor(k43)}';

    testWidgets('modelo, número, CNPJ da chave, blocos, situação, QR e copiar', (t) async {
      _mockClipboard(t);
      await _pump(
        t,
        SsNfeCard(
          accessKey: key,
          issuer: 'Mercado Exemplo',
          issuedAt: DateTime(2026, 11, 26),
          amountCents: 8990,
          status: SsNfeStatus.authorized,
          qrUrl: 'https://exemplo.gov.br/q?p=$key',
          onOpen: () {},
        ),
      );
      expect(find.text('NFC-e'), findsOneWidget);
      expect(find.text('Nº 789 · série 2'), findsOneWidget);
      expect(find.text('11.222.333/0001-81'), findsOneWidget);
      expect(find.text('26/11/2026'), findsOneWidget);
      expect(find.text(SsBr.formatNfeKey(key)), findsOneWidget);
      expect(find.text('Autorizada'), findsOneWidget);
      expect(find.bySemanticsLabel('QR Code da consulta'), findsOneWidget);
      expect(find.text('O dígito verificador da chave não confere.'), findsNothing);
      await ssA11yAudit(t);
      await t.tap(find.text('Copiar chave'));
      await t.pump();
      expect(_clip, key);
      expect(find.text('Chave copiada'), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      await _pump(t, SsNfeCard(accessKey: _flip(key, 43), status: SsNfeStatus.canceled));
      expect(find.text('O dígito verificador da chave não confere.'), findsOneWidget);
      expect(find.text('Cancelada'), findsOneWidget);
    });
  });

  group('SsSmartPaste', () {
    testWidgets('reconhece ao digitar, mostra as ações do tipo e do also e chama com o match', (t) async {
      SsPasteMatch? usado;
      final detectados = <SsPasteType?>[];
      await _pump(
        t,
        SsSmartPaste(
          today: _hoje,
          onDetected: (m) => detectados.add(m?.type),
          actions: {
            SsPasteType.boleto: [SsPasteAction('Pagar boleto', (m) => usado = m, primary: true)],
            SsPasteType.pixKey: [SsPasteAction('Enviar Pix', (m) => usado = m)],
            SsPasteType.cpf: [SsPasteAction('Ver cliente', (m) => usado = m)],
          },
        ),
      );
      expect(find.text('Cole algo e a gente diz o que é.'), findsOneWidget);
      await ssA11yAudit(t);
      await t.enterText(find.byType(TextField), _linha);
      await t.pumpAndSettle();
      expect(find.text('Isso parece um boleto de R\$ 123,45 com vencimento em 10/12/2026'), findsOneWidget);
      await ssA11yAudit(t);
      await t.tap(find.text('Pagar boleto'));
      expect(usado!.type, SsPasteType.boleto);
      expect(usado!.amountCents, 12345);
      await t.enterText(find.byType(TextField), '604.721.385-53');
      await t.pumpAndSettle();
      expect(find.text('Isso parece um CPF: 604.721.385-53'), findsOneWidget);
      expect(find.text('Ver cliente'), findsOneWidget);
      expect(find.text('Enviar Pix'), findsOneWidget);
      await t.tap(find.text('Enviar Pix'));
      expect(usado!.value, '60472138553');
      expect(detectados, [SsPasteType.boleto, SsPasteType.cpf]);
    });

    testWidgets('Colar lê a área de transferência; ✕ limpa; DV errado avisa', (t) async {
      _mockClipboard(t);
      _clip = _pix;
      await _pump(t, SsSmartPaste(today: _hoje));
      await t.tap(find.ssTooltip('Colar'));
      await t.pumpAndSettle();
      expect(find.text('Isso parece um Pix de R\$ 123,45 para LOJA EXEMPLO'), findsOneWidget);
      await t.tap(find.ssTooltip('Limpar'));
      await t.pumpAndSettle();
      expect(find.text('Cole algo e a gente diz o que é.'), findsOneWidget);
      await t.enterText(find.byType(TextField), _flip(SsBr.digits(_linha), 2));
      await t.pumpAndSettle();
      expect(find.text('Parece um boleto, mas os números não conferem.'), findsOneWidget);
    });
  });

  group('campos', () {
    testWidgets('SsPixKeyField: tipo embaixo, chave normalizada e formatada ao sair', (t) async {
      String? chave;
      SsPixKeyType? tipo;
      await _pump(
        t,
        Column(
          children: [
            SsPixKeyField(
              onChanged: (k, ty) {
                chave = k;
                tipo = ty;
              },
            ),
            const SsTextField(label: 'Outro'),
          ],
        ),
      );
      await t.enterText(find.byType(TextField).first, '11987654321');
      await t.pump();
      expect(tipo, SsPixKeyType.phone);
      expect(chave, '+5511987654321');
      expect(find.text('Telefone'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, '60472138553');
      await t.pump();
      expect(tipo, SsPixKeyType.cpf);
      await t.tap(find.byType(TextField).last);
      await t.pump();
      expect(find.text('604.721.385-53'), findsWidgets);
      await ssA11yAudit(t);
      await t.enterText(find.byType(TextField).first, 'abc');
      await t.tap(find.byType(TextField).last);
      await t.pump();
      await t.pump();
      expect(tipo, isNull);
      expect(find.textContaining('Chave Pix inválida'), findsOneWidget);
    });

    testWidgets('SsBoletoField: máscara, valor e vencimento, DV errado e ler o código', (t) async {
      SsBoleto? lido;
      await _pump(
        t,
        Column(
          children: [
            SsBoletoField(
              today: _hoje,
              onChanged: (b) => lido = b,
              onScan: () async => '34191165600000123451090000012345678901234567',
            ),
            const SsTextField(label: 'Outro'),
          ],
        ),
      );
      await t.enterText(find.byType(TextField).first, SsBr.digits(_linha));
      await t.pump();
      expect(find.text(_linha), findsOneWidget);
      expect(lido!.amountCents, 12345);
      expect(find.text('Boleto bancário'), findsOneWidget);
      expect(find.text('R\$ 123,45 · Vence em 10/12/2026'), findsOneWidget);
      await ssA11yAudit(t);
      await t.enterText(find.byType(TextField).first, _flip(SsBr.digits(_linha), 2));
      await t.tap(find.byType(TextField).last);
      await t.pump();
      await t.pump();
      expect(lido, isNull);
      expect(find.text('Algum número não confere. Confira a linha digitável.'), findsOneWidget);
      await t.tap(find.ssTooltip('Ler código de barras'));
      await t.pump();
      expect(find.text(_linha), findsOneWidget);
      expect(lido!.valid, isTrue);
    });

    testWidgets('SsCepField: busca, preenche os campos ligados e ignora resposta velha', (t) async {
      final rua = TextEditingController(), cidade = TextEditingController(), uf = TextEditingController();
      final pedidos = <String, Completer<SsAddress?>>{};
      await _pump(
        t,
        SsCepField(
          street: rua,
          city: cidade,
          state: uf,
          onLookup: (cep) => (pedidos[cep] = Completer<SsAddress?>()).future,
        ),
      );
      await t.enterText(find.byType(TextField), '01310100');
      await t.pump();
      expect(find.text('01310-100'), findsOneWidget);
      expect(find.text('Buscando o endereço…'), findsOneWidget);
      await t.enterText(find.byType(TextField), '20040020');
      await t.pump();
      pedidos['20040020']!.complete(const SsAddress(street: 'Avenida Rio Branco', city: 'Rio de Janeiro', state: 'RJ'));
      await t.pump();
      pedidos['01310100']!.complete(const SsAddress(street: 'Avenida Paulista', city: 'São Paulo', state: 'SP'));
      await t.pump();
      expect(rua.text, 'Avenida Rio Branco');
      expect(uf.text, 'RJ');
      expect(find.text('Avenida Rio Branco · Rio de Janeiro/RJ'), findsOneWidget);
      await ssA11yAudit(t);
      await t.enterText(find.byType(TextField), '99999999');
      await t.pump();
      pedidos['99999999']!.complete(null);
      await t.pump();
      expect(find.text('CEP não encontrado. Preencha o endereço.'), findsOneWidget);
    });

    testWidgets('SsDocumentField: CPF/CNPJ, DV e a razão social pelo onLookup', (t) async {
      String? doc, tipo;
      await _pump(
        t,
        Column(
          children: [
            SsDocumentField(
              onChanged: (d, k) {
                doc = d;
                tipo = k;
              },
              onLookup: (cnpj) async => cnpj == '11222333000181' ? 'Loja Exemplo Comércio Ltda' : null,
            ),
            const SsTextField(label: 'Outro'),
          ],
        ),
      );
      await t.enterText(find.byType(TextField).first, '11222333000181');
      await t.pump();
      await t.pump();
      expect(find.text('11.222.333/0001-81'), findsOneWidget);
      expect(doc, '11222333000181');
      expect(tipo, 'cnpj');
      expect(find.text('Loja Exemplo Comércio Ltda'), findsOneWidget);
      await ssA11yAudit(t);
      await t.enterText(find.byType(TextField).first, '12345678900');
      await t.tap(find.byType(TextField).last);
      await t.pump();
      await t.pump();
      expect(doc, isNull);
      expect(find.text('CPF inválido. Confira os 11 dígitos.'), findsOneWidget);
    });

    testWidgets('alvos de 48 e o leitor de tela no compacto', (t) async {
      await _pump(
        t,
        Column(
          children: [
            const SsPixKeyField(initialValue: '+5511987654321'),
            SsBoletoField(initialValue: _linha, onScan: () async => null, today: _hoje),
            const SsCepField(initialValue: '01310100'),
            const SsDocumentField(initialValue: '60472138553'),
            SsSmartPaste(initialValue: '604.721.385-53', today: _hoje),
          ],
        ),
        density: SsDensity.compact,
      );
      await t.pump();
      await ssA11yAudit(t);
    });
  });
}
