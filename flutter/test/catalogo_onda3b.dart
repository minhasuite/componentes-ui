// Entradas do catálogo da onda3b.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}
Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);

const _statusPedido = {
  'pago': SsTone.success,
  'aberto': SsTone.info,
  'aprovacao': SsTone.warning,
  'vencido': SsTone.danger,
  'rascunho': SsTone.neutral,
  'novo': SsTone.accent,
};

Widget _linha(BuildContext ctx, String titulo, String sub) {
  final c = SsColors.of(ctx);
  return Container(
    color: c.surface,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(color: c.ink, fontWeight: FontWeight.w700),
              ),
              Text(
                sub,
                style: TextStyle(color: c.muted, fontSize: AppType.meta),
              ),
            ],
          ),
        ),
        Text(r'R$ 12,90', style: AppTheme.number(ctx, size: AppType.body)),
      ],
    ),
  );
}

Widget _swipe(BuildContext ctx) => SsSwipeAction(
  start: const SsSwipeSide(icon: Icons.check_rounded, label: 'Comprei', color: AppColors.success, onTrigger: _nada),
  end: const SsSwipeSide(
    icon: Icons.delete_outline_rounded,
    label: 'Excluir',
    color: AppColors.danger,
    destructive: true,
    onTrigger: _nada,
  ),
  child: _linha(ctx, 'Leite integral 1 L', 'Lista da semana · 2 un.'),
);

/// Arrasta o filho [fracao] da largura (negativo = para a esquerda) por
/// eventos de ponteiro e não solta (soltar ou cancelar encerra o gesto): o
/// item fica parado no meio. Um ponteiro novo por demo.
class _Arrasta extends StatefulWidget {
  const _Arrasta(this.fracao, this.child);
  final double fracao;
  final Widget child;

  @override
  State<_Arrasta> createState() => _ArrastaState();
}

class _ArrastaState extends State<_Arrasta> {
  static var _ponteiro = 700;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject()! as RenderBox;
      final p = box.localToGlobal(box.size.center(Offset.zero));
      final passo = Offset(box.size.width * widget.fracao / 12, 0);
      final g = GestureBinding.instance;
      final id = _ponteiro++;
      g.handlePointerEvent(PointerDownEvent(pointer: id, position: p));
      // Folga do gesto (~18 px) antes de contar.
      final folga = Offset(widget.fracao.sign * 20, 0);
      g.handlePointerEvent(PointerMoveEvent(pointer: id, position: p + folga, delta: folga));
      var at = p + folga;
      for (var i = 0; i < 12; i++) {
        at += passo;
        g.handlePointerEvent(PointerMoveEvent(pointer: id, position: at, delta: passo));
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final catalogoOnda3b = <Componente>[
  Componente(
    'ss-swipe-action',
    'SsSwipeAction · SsSwipeSide',
    'Deslizar o item para os lados revela o fundo colorido com ícone e rótulo, para uma ação rápida (comprei, excluir).',
    comportamentos: [
      'Até 35% da largura o fundo ganha cor e o ícone cresce.',
      'Depois do limite o item resiste (elástico), dá um tique e o ícone dá um "pop".',
      'Soltar depois do limite aciona; antes, o item volta com mola.',
      'Destrutivo: o item sai encolhendo a altura e some da lista.',
      'Leitor de tela aciona cada lado pelas ações personalizadas.',
    ],
    estados: [
      Estado('repouso', 'em repouso', (ctx) => Center(child: _swipe(ctx)), tamanho: const Size(360, 90)),
      Estado(
        'deslizando',
        'puxando para a direita (antes do limite)',
        (ctx) => Center(child: _Arrasta(.25, _swipe(ctx))),
        tamanho: const Size(360, 90),
      ),
      Estado(
        'armado',
        'puxando para a esquerda (passou do limite)',
        (ctx) => Center(child: _Arrasta(-.6, _swipe(ctx))),
        tamanho: const Size(360, 90),
      ),
    ],
  ),
  Componente(
    'ss-status-badge',
    'SsStatusBadge · SsTone',
    'Situação de um registro em pílula com ponto + texto; o app mapeia status → tom semântico.',
    comportamentos: [
      'Seis tons: neutro, informação, sucesso, aviso, perigo e marca.',
      'Status fora do mapa sai neutro.',
      'A cor nunca vai sozinha: ponto e texto juntos.',
    ],
    estados: [
      Estado(
        'tons',
        'os seis tons',
        (_) => _pad(
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              SsStatusBadge('pago', map: _statusPedido, label: 'Pago'),
              SsStatusBadge('aberto', map: _statusPedido, label: 'Em aberto'),
              SsStatusBadge('aprovacao', map: _statusPedido, label: 'Aguardando aprovação'),
              SsStatusBadge('vencido', map: _statusPedido, label: 'Vencido'),
              SsStatusBadge('rascunho', map: _statusPedido, label: 'Rascunho'),
              SsStatusBadge('novo', map: _statusPedido, label: 'Novo'),
            ],
          ),
        ),
        tamanho: const Size(360, 120),
      ),
    ],
  ),
  Componente(
    'ss-value-row',
    'SsValueRow · SsDashedDivider',
    'Linha "rótulo … valor" de detalhe e recibo, com o valor em DM Mono; divisória tracejada antes do total.',
    comportamentos: [
      'O rótulo não é espremido: o valor encolhe (DM Mono) ou quebra (texto) antes.',
      'caption vai embaixo do rótulo; emphasis marca o total.',
      'Com onTap, a linha é tocável e ganha uma seta.',
    ],
    estados: [
      Estado(
        'recibo',
        'resumo com total',
        (_) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsValueRow('Subtotal', r'R$ 1.231,70'),
              SsValueRow('Frete', r'R$ 18,90', caption: 'PAC · 5 dias úteis'),
              SsValueRow('Pagamento', 'Pix na entrega', mono: false, onTap: _nada),
              SsDashedDivider(),
              SsValueRow('Total', r'R$ 1.250,60', emphasis: true),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
      ),
      Estado(
        'apertado',
        'valor grande em pouco espaço',
        (_) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: SizedBox(
              width: 220,
              child: SsValueRow('Saldo devedor', r'R$ 1.234.567,89', caption: 'em 12 parcelas'),
            ),
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-highlight',
    'SsHighlight',
    'Realce de "acabou de salvar": um véu na cor da marca a 14% acende e some em ~600 ms, no lugar do toast.',
    comportamentos: [
      'Acende quando active passa a verdadeiro ou quando o item nasce ativo.',
      'Acende rápido e apaga devagar; não bloqueia o toque.',
      'Com menos animação no sistema, aparece e some sem esmaecer.',
    ],
    estados: [
      Estado(
        'aceso',
        'no pico do realce',
        (ctx) => Center(child: SsHighlight(active: true, radius: 0, child: _linha(ctx, 'Arroz 5 kg', 'Salvo agora'))),
        aguarde: 120,
      ),
    ],
  ),
  Componente(
    'ss-offer-card',
    'SsOfferCard',
    'Oferta de uma loja para comparar preço: fonte, título, preço em DM Mono, preço antigo riscado e nota.',
    comportamentos: [
      'best põe a fita "Mais barata", a borda e o preço em verde.',
      'O preço ocupa até 40% da largura e encolhe para caber.',
      'Toque com encolhida e tique leve; o leitor de tela lê tudo numa frase.',
    ],
    estados: [
      Estado(
        'comparando',
        'mais barata e outra oferta',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsOfferCard(
                source: 'Mercado Livre',
                title: 'Air Fryer Mondial 4 L Preta',
                price: r'R$ 329,90',
                oldPrice: r'R$ 399,00',
                note: 'à vista no Pix',
                best: true,
                onTap: _nada,
              ),
              SizedBox(height: 10),
              SsOfferCard(
                source: 'Amazon',
                title: 'Air Fryer Mondial 4 L Preta',
                price: r'R$ 359,00',
                note: r'ou 10x de R$ 35,90',
                onTap: _nada,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 270),
      ),
    ],
  ),
  Componente(
    'ss-deal-badge',
    'SsDealBadge · SsSourceChip',
    'Selo de promoção em DM Mono no tom pedido e chip de loja/site com iniciais coloridas pelo nome.',
    comportamentos: [
      'Selo verde por padrão (preço caiu); qualquer SsTone.',
      'Chip: favicon, ícone ou iniciais (a mesma cor sempre para o mesmo nome).',
    ],
    estados: [
      Estado(
        'padrao',
        'selos e chips',
        (_) => _pad(
          const Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SsDealBadge('−18%'),
              SsDealBadge('Subiu 6%', tone: SsTone.danger),
              SsDealBadge('Frete grátis', tone: SsTone.info),
              SsSourceChip('Mercado Livre'),
              SsSourceChip('Magazine Luiza'),
              SsSourceChip('Booking', icon: Icons.hotel_outlined),
            ],
          ),
        ),
        tamanho: const Size(360, 120),
      ),
    ],
  ),
  Componente(
    'ss-net-image',
    'SsNetImage',
    'Foto da rede com listras diagonais na cor do campo enquanto carrega, no erro ou sem endereço, e fade ao chegar.',
    comportamentos: [
      'Vazio com as iniciais do nome ou com o ícone.',
      'Decodifica no tamanho da tela (cacheWidth pelo devicePixelRatio).',
      'Sem cache em disco: só o de memória do Flutter.',
    ],
    estados: [
      Estado(
        'vazio',
        'sem foto: iniciais e ícone',
        (_) => _pad(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsNetImage(null, width: 64, height: 64, name: 'Leite Integral'),
              SizedBox(width: 12),
              SsNetImage(null, width: 64, height: 64, fallbackIcon: Icons.local_florist_outlined),
              SizedBox(width: 12),
              SsNetImage(null, width: 120, height: 64, radius: AppRadius.card),
            ],
          ),
        ),
      ),
    ],
  ),
];
