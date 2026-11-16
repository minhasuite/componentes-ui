// v0.26: conversa entre pessoas (cliente e atendente). O que mudou no SsChatBubble ([comV26]) e o SsChatDivider novo.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

class _Conversa extends StatelessWidget {
  const _Conversa();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: const [
      SsChatDivider(label: 'Ontem'),
      SsChatBubble(
        text: 'Boa tarde! O pedido 2904 já saiu?',
        fromMe: false,
        aiMark: false,
        author: 'Mercado Sabor Caseiro',
        time: '17:40',
      ),
      SsChatDivider(label: 'Hoje'),
      SsChatBubble(
        text: 'Saiu hoje cedo, chega até as 15h.',
        fromMe: true,
        author: 'Ana · pelo celular',
        time: '09:12',
        status: SsChatStatus.read,
      ),
      SsChatBubble(text: 'Obrigado!', fromMe: false, aiMark: false, time: '09:15'),
    ],
  );
}

class _Situacoes extends StatelessWidget {
  const _Situacoes();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: const [
      SsChatBubble(text: 'Enviando', fromMe: true, time: '10:01', status: SsChatStatus.sending),
      SsChatBubble(text: 'Enviada', fromMe: true, time: '10:02', status: SsChatStatus.sent),
      SsChatBubble(text: 'Entregue', fromMe: true, time: '10:03', status: SsChatStatus.delivered),
      SsChatBubble(text: 'Lida', fromMe: true, time: '10:04', status: SsChatStatus.read),
      SsChatBubble(text: 'Sem rede', fromMe: true, time: '10:05', status: SsChatStatus.failed),
    ],
  );
}

final Map<String, (List<String>, List<Estado>)> _v26 = {
  'ss-chat': (
    [
      'v0.26: conversa entre pessoas. aiMark: false tira o ✦ da bolha da outra pessoa (o horário encosta na bolha); '
          'author: põe quem escreveu no alto da bolha, pequeno e em negrito (no meu, em branco translúcido sobre a marca).',
      'v0.26: situação entregue (✓✓ apagado) e lida (✓✓ na tinta da marca), com o nome no leitor de tela '
          '("Entregue", "Lida"), além de enviando, enviada e não enviada.',
    ],
    [
      Estado('pessoas', 'cliente e atendente (v0.26)', (_) => const _Conversa(), tamanho: const Size(360, 340)),
      Estado(
        'situacoes',
        'enviando · enviada · entregue · lida · não enviada (v0.26)',
        (_) => const _Situacoes(),
        tamanho: const Size(360, 380),
      ),
    ],
  ),
};

List<Componente> comV26(List<Componente> base) => [
  for (final c in base)
    if (_v26[c.slug] case (final comp, final est))
      Componente(
        c.slug,
        c.nome,
        c.descricao,
        comportamentos: [...c.comportamentos, ...comp],
        estados: [...c.estados, ...est],
      )
    else
      c,
  Componente(
    'ss-chat-divider',
    'SsChatDivider',
    'Separador de dia numa conversa (v0.26, par do Ss::ChatDividerComponent): "Hoje", "Ontem", "12/11".',
    comportamentos: [
      'Rótulo pequeno numa pílula em field, centrado entre duas linhas finas (line).',
      'O leitor de tela lê só o rótulo, como um nó próprio.',
    ],
    estados: [
      Estado(
        'hoje',
        'Hoje',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsChatDivider(label: 'Hoje'),
        ),
        tamanho: const Size(360, 72),
      ),
    ],
  ),
];
