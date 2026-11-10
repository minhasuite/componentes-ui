// Estados e comportamentos da v0.18 (o meu-financeiro-app 100% no pacote): peça
// nova em [catalogoV18] e os extras das que já existiam (por slug) em [comV18].
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// O botão no canto de baixo, como no `floatingActionButton`.
Widget _canto(Widget w) => Align(
  alignment: Alignment.bottomRight,
  child: Padding(padding: const EdgeInsets.all(16), child: w),
);

List<SsSpeedDialAction> get _acoes => const [
  SsSpeedDialAction('Lançamento', Icons.add_rounded, _nada),
  SsSpeedDialAction('Registrar com IA', Icons.auto_awesome, _nada, tooltip: 'Registrar compra com IA'),
  SsSpeedDialAction('Ler boleto ou Pix', Icons.qr_code_scanner_rounded, _nada),
];

/// Toca no filho depois do 1º quadro (o estado "aberto" do catálogo).
class _AbreSozinho extends StatefulWidget {
  const _AbreSozinho({required this.child});
  final Widget child;

  @override
  State<_AbreSozinho> createState() => _AbreSozinhoState();
}

class _AbreSozinhoState extends State<_AbreSozinho> {
  final _k = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _k.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final p = box.localToGlobal(box.size.center(Offset.zero));
      GestureBinding.instance.handlePointerEvent(PointerDownEvent(pointer: 918, position: p));
      GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: 918, position: p));
    });
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _k, child: widget.child);
}

class _MoneyComTexto extends StatefulWidget {
  const _MoneyComTexto(this.texto);
  final String texto;

  @override
  State<_MoneyComTexto> createState() => _MoneyComTextoState();
}

class _MoneyComTextoState extends State<_MoneyComTexto> {
  late final _c = TextEditingController(text: widget.texto);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SsMoneyField(controller: _c, label: 'Valor', expression: true, required: true, calculator: false);
}

final catalogoV18 = <Componente>[
  Componente(
    'ss-speed-dial',
    'SsSpeedDial',
    'Botão flutuante com várias ações (lançamento, registrar com IA, ler boleto): o toque abre a lista acima do botão.',
    comportamentos: [
      'Toque abre a lista: rótulo em pílula + mini botão, a primeira ação mais perto do botão.',
      'O "+" gira até virar "×"; as ações sobem com a mola, uma depois da outra.',
      'Véu escuro por cima da tela: tocar nele, no × ou no voltar do sistema fecha; escolher uma ação fecha e roda a ação.',
      'Uma ação só: vira o SsFab direto com o ícone e o rótulo dela (sem lista); sem ações, nada.',
      'Botão fechado igual ao SsFab (label, extended, extendedFrom); sem label, círculo com "Ações rápidas" na dica e no leitor, com o estado aberto/fechado.',
      'Cada ação é um botão com alvo de 48 e o nome lido (tooltip ou label); onOpenChanged avisa quando abre e fecha.',
      'Reduzir movimento: abre e fecha sem animação.',
    ],
    estados: [
      Estado(
        'fechado',
        'fechado (círculo)',
        (_) => _canto(SsSpeedDial(actions: _acoes)),
        tamanho: const Size(360, 120),
      ),
      Estado(
        'fechado-rotulo',
        'fechado com rótulo',
        (_) => _canto(SsSpeedDial(label: 'Novo', actions: _acoes)),
        tamanho: const Size(360, 120),
      ),
      Estado(
        'aberto',
        'aberto',
        // Navegador próprio: a lista abre dentro da área capturada.
        (_) => Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => Scaffold(
              backgroundColor: Colors.transparent,
              body: _canto(_AbreSozinho(child: SsSpeedDial(useRootNavigator: false, actions: _acoes))),
            ),
          ),
        ),
        tamanho: const Size(360, 340),
        aguarde: 700,
      ),
      Estado(
        'uma-acao',
        'uma ação só (vira SsFab)',
        (_) => _canto(const SsSpeedDial(actions: [SsSpeedDialAction('Lançamento', Icons.add_rounded, _nada)])),
        tamanho: const Size(360, 120),
      ),
    ],
  ),
];

/// Soma os extras da v0.18 às entradas de [base] com o mesmo slug.
List<Componente> comV18(List<Componente> base) => [
  for (final c in base)
    if (_v18[c.slug] case (final comp, final est))
      Componente(
        c.slug,
        c.nome,
        c.descricao,
        comportamentos: [...c.comportamentos, ...comp],
        estados: [...c.estados, ...est],
      )
    else
      c,
];

final Map<String, (List<String>, List<Estado>)> _v18 = {
  'ss-money-field': (
    [
      'v0.18: controller (texto em reais, "1.234,56" / "45+12,50"): o que o app escreve aparece; o que a pessoa digita vai para ele. Leia com SsMoneyField.parse.',
      'v0.18: focusNode, autofocus, textInputAction, onSubmitted; required (vazio → "Informe um valor") e errorText (erro do servidor).',
      'v0.18: calculator: false tira a calculadora do modo conta; onKeypad abre o teclado do app.',
    ],
    [
      Estado(
        'controller-conta',
        'controller com conta preenchida de fora',
        (_) => _pad(const _MoneyComTexto('45+12,50')),
        tamanho: const Size(360, 140),
      ),
    ],
  ),
  'ss-top-bar': (
    [
      'v0.18: no lugar do AppBar: title + subtitle em duas linhas, actions, voltar automático, bottom (TabBar) e PreferredSize com a altura do bottom; style: dark no leitor de código.',
    ],
    [
      Estado(
        'detalhe',
        'detalhe com subtítulo e ações (fatura)',
        (_) => SizedBox(
          height: 56,
          child: SsTopBar(
            title: 'Nubank',
            subtitle: 'Fecha dia 3 · vence dia 10',
            actions: [
              SsIconButton(icon: Icons.group_outlined, tooltip: 'Fatura por pessoa', onPressed: _nada),
              SsIconButton(icon: Icons.ios_share, tooltip: 'Exportar fatura', onPressed: _nada),
            ],
          ),
        ),
        tamanho: const Size(390, 56),
      ),
    ],
  ),
  'ss-toast': (
    [
      'v0.18: sem BuildContext de tela (push com o app aberto): SsToastHost.navigatorKey = a chave do navegador do app e showSsToastGlobal / showSsUndoGlobal.',
    ],
    const [],
  ),
  'ss-fab': (['v0.18: iconTurns gira o ícone (o SsSpeedDial usa no "+" → "×").'], const []),
};
