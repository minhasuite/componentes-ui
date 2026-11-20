// v1.8: cartão de conquista ([catalogoV180]: ss-achievement), par do Ss::AchievementCardComponent.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

Widget _grade() => Padding(
  padding: const EdgeInsets.all(16),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Expanded(
        child: SsAchievementCard(
          title: 'Primeiro turno coberto',
          description: 'Cobriu um turno aberto da escala.',
          earned: true,
          caption: 'em 12/11',
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: SsAchievementCard(
          title: '30 dias seguidos',
          description: 'Sequência de 30 dias escalados com tudo feito.',
          icon: SsIcons.named('fire'),
          progress: 12 / 30,
          progressLabel: '12 de 30 dias',
        ),
      ),
    ],
  ),
);

final catalogoV180 = <Componente>[
  Componente(
    'ss-achievement',
    'SsAchievementCard',
    'Cartão de conquista (v1.8, par do Ss::AchievementCardComponent): medalhão com o ícone, título, a regra e o rodapé (selo "Conquistada" ou a barra do que falta).',
    comportamentos: [
      'earned: medalhão na cor da marca e o selo "Conquistada" com o caption ("em 12/11").',
      'Sem earned: medalhão apagado; com progress (0 a 1) a barra fina (SsProgress) e o progressLabel ("12 de 30 dias").',
      'Ícone padrão: o "trophy" do conjunto da suíte (SsIcons.named(\'trophy\'), o mesmo badge-check do web).',
      'Leitor de tela: um nó só, "Conquista: título. Conquistada em 12/11. A regra." ou "Falta: 12 de 30 dias.".',
      'Sem altura fixa: serve em 2 colunas num celular de 360 e com texto 1,6× (o texto quebra, a altura cresce).',
    ],
    estados: [
      Estado('grade', 'conquistada e em andamento', (_) => _grade(), tamanho: const Size(360, 280), aguarde: 1200),
      Estado(
        'bloqueada',
        'ainda sem progresso',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsAchievementCard(
            title: '100 checklists no prazo',
            description: 'Conclua 100 checklists antes do prazo.',
          ),
        ),
        tamanho: const Size(240, 200),
      ),
    ],
  ),
];
