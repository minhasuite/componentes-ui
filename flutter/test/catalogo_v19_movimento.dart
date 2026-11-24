// v1.9 · movimento ([comV19Movimento]): tokens e vibração no ss-motion, cores do sistema no
// ss-appearance-panel, a correção do ss-paged-list e as peças novas ss-skeleton-switch e
// ss-undoable-removal (pares da transição do .ss-skel e do controller ss-undoable do web).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

Widget _painelSistema() => SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: SsAppearancePanel(
    controller: SsAppearanceController(
      brand: SsBrand.ambar,
      read: () async => null,
      write: (_) async {},
      initial: const SsAppearance(paleta: SsAppearance.sistema),
      systemColor: const Color(0xFF3F6CB8),
    ),
  ),
);

/// Skeleton → conteúdo, parado no meio da troca (o catálogo captura com `aguarde`).
class _Troca extends StatefulWidget {
  const _Troca();
  @override
  State<_Troca> createState() => _TrocaState();
}

class _TrocaState extends State<_Troca> {
  AsyncValue<List<String>> _v = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _v = const AsyncValue.data(['Arroz 5 kg', 'Feijão 1 kg', 'Café 500 g']));
    });
  }

  @override
  Widget build(BuildContext context) => SsAsyncBody<List<String>>(
    value: _v,
    loading: const SkeletonList(count: 3),
    data: (l) => ListView(
      padding: const EdgeInsets.all(16),
      children: [for (final s in l) SsCard(child: Text(s))],
    ),
  );
}

/// Lista com um item saindo (encolhido pela metade).
class _Saindo extends StatefulWidget {
  const _Saindo();
  @override
  State<_Saindo> createState() => _SaindoState();
}

class _SaindoState extends State<_Saindo> {
  final _chave = GlobalKey<SsUndoableRemovalState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _chave.currentState?.remove());
  }

  Widget _item(String nome, {Key? key}) => SsUndoableRemoval(
    key: key,
    message: '$nome removido',
    onCommit: () async {},
    builder: (_, remove) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SsCard(child: Text(nome)),
    ),
  );

  @override
  Widget build(BuildContext context) => _pad(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _item('Arroz'),
        _item('Feijão', key: _chave),
        _item('Café'),
      ],
    ),
  );
}

final Map<String, (List<String>, List<Estado>)> _v19 = {
  'ss-motion': (
    [
      'v1.9 · tokens únicos (a mesma tabela do CSS): SsMotion.short/medium/long = 180/280/400 ms (--ss-dur-short/medium/long); fast/base/slow continuam como nomes antigos.',
      'Curvas: standard Cubic(.2,0,0,1), enter easeOutCubic, exit easeInCubic, spring easeOutBack, bounce a mola (--ss-ease-standard/enter/exit/spring, --ss-bounce). Distâncias distSmall/Medium/Large = 4/12/24 px (--ss-dist-*).',
      'As durações soltas dos componentes viraram os tokens (150–220 → short, 240–300 → medium, 380–400 → long); o que tem ritmo próprio (indicador 460, mola do toque 420, minhoca 520) ficou.',
      'v1.9 · mapa de vibração: SsHaptics.selection (chave, segmentado), limit (slider no mínimo/máximo), success (confirmação), warning (confirmação perigosa, remoção com desfazer), error (toast de erro). SsHaptics.enabled = false desliga tudo.',
    ],
    const <Estado>[],
  ),
  'ss-appearance-panel': (
    [
      'v1.9 · Cores do sistema (Material You, Android 12+): o app passa SsAppearanceController(systemColor:) (ex. lida pelo dynamic_color) e a 2ª ficha vira "Cores do sistema"; a marca sai de SsBrand.fromColors, escurecida até o branco passar 4,5:1.',
      'O JSON guarda "paleta": "sistema"; sem a cor (iOS, Android antigo) a opção some e vale a cor do app. controller.systemColor = nova troca o tema na hora.',
    ],
    [Estado('sistema', 'cores do sistema escolhidas', (_) => _painelSistema(), tamanho: const Size(390, 520))],
  ),
  'ss-paged-list': (
    [
      'v1.9: com onRefresh: a lista não perde a altura (o "Vertical viewport was given unbounded height" saiu); não precisa mais do SsPullToRefresh por fora.',
    ],
    const <Estado>[],
  ),
  'ss-async-body': (
    [
      'v1.9: do skeleton (ou do erro) para o conteúdo com crossfade e subida de 12 px (SsSkeletonSwitch, 280 ms); revalidar não anima.',
    ],
    const <Estado>[],
  ),
  'ss-async-sliver': (
    [
      'v1.9: quando o dado chega depois do skeleton, a lista entra esmaecendo (SsSliverEntrance); dado que já estava não anima.',
    ],
    const <Estado>[],
  ),
};

final List<Componente> _novos = [
  Componente(
    'ss-skeleton-switch',
    'SsSkeletonSwitch / SsSliverEntrance',
    'Skeleton que vira conteúdo (v1.9, par da transição do .ss-skel no turbo-frame): crossfade e subida curta em vez de troca seca.',
    comportamentos: [
      'stateKey diz o estado (carregando, dado, erro, vazio): trocar de estado anima, o mesmo estado com dado novo não.',
      'Quem chega aparece e sobe SsMotion.distMedium (12 px) em SsMotion.medium com SsMotion.enter; quem sai só esmaece.',
      'Layout do filho: durante a troca os dois ficam empilhados com as restrições do pai.',
      'SsSliverEntrance: a versão para sliver (só esmaece, para não mexer na rolagem).',
      'Com menos movimento, troca direto.',
    ],
    estados: [
      Estado(
        'troca',
        'skeleton virando a lista (no meio)',
        (_) => const _Troca(),
        tamanho: const Size(360, 260),
        aguarde: 180,
      ),
    ],
  ),
  Componente(
    'ss-undoable-removal',
    'SsUndoableRemoval',
    'Remoção otimista com desfazer animado (v1.9, par do controller ss-undoable do web): o item sai encolhendo e o "Desfazer" do SsToast o traz de volta no mesmo lugar.',
    comportamentos: [
      'builder: (context, remove): o item chama remove(); ele encolhe (altura, opacidade e escala 0,94) em SsMotion.medium com SsMotion.exit.',
      'O aviso é o showSsUndo (contagem na borda). Desfez: volta crescendo no mesmo lugar (SsMotion.enter) e chama onUndo.',
      'Não desfez: onCommit (a exclusão de verdade) e depois onRemoved (o app tira da lista).',
      'onCommit falhou: o item volta e aparece o aviso de erro (errorMessage), com a vibração de erro.',
      'Vibração: warning ao remover, selection ao desfazer. Fora da árvore de semântica enquanto espera. Com menos movimento, some e volta sem animar.',
    ],
    estados: [
      Estado('saindo', 'o item do meio saindo', (_) => const _Saindo(), tamanho: const Size(360, 240), aguarde: 140),
    ],
  ),
];

List<Componente> comV19Movimento(List<Componente> base) => [
  for (final c in base)
    if (_v19[c.slug] case (final comp, final est))
      Componente(
        c.slug,
        c.nome,
        c.descricao,
        comportamentos: [...c.comportamentos, ...comp],
        estados: [...c.estados, ...est],
      )
    else
      c,
  ..._novos,
];
