// Entradas do catálogo da onda1.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}
Future<void> _nadaAsync() async {}
Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);
const _tela = Size(360, 420);
const _dialogo = Size(360, 460);

const _itens = ['Pedido 1042 · R\$ 1.250,00', 'Pedido 1041 · R\$ 380,00', 'Pedido 1040 · R\$ 92,50'];

Widget _lista(List<String> l) => ListView(
  padding: const EdgeInsets.all(16),
  children: [for (final t in l) SsListItem(icon: Icons.receipt_long_outlined, title: t, subtitle: 'Hoje')],
);

Widget _corpo(AsyncValue<List<String>> v, {bool Function(Object)? offline}) => SsAsyncBody<List<String>>(
  value: v,
  data: _lista,
  onRetry: _nada,
  isOffline: offline,
  isEmpty: (l) => l.isEmpty,
  empty: const SsEmptyState(
    icon: Icons.inbox_outlined,
    title: 'Nenhum pedido',
    subtitle: 'Os pedidos do dia aparecem aqui.',
  ),
);

final _revalidando = const AsyncLoading<List<String>>().copyWithPrevious(const AsyncData(_itens));

/// Começa offline e volta logo depois do 1º quadro (mostra o "De volta online").
class _OfflineDemo extends StatefulWidget {
  const _OfflineDemo({required this.volta});
  final bool volta;

  @override
  State<_OfflineDemo> createState() => _OfflineDemoState();
}

class _OfflineDemoState extends State<_OfflineDemo> {
  bool offline = true;

  @override
  void initState() {
    super.initState();
    if (widget.volta) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => offline = false));
  }

  @override
  Widget build(BuildContext context) => SsOfflineBanner(offline: offline, child: _lista(_itens));
}

final catalogoOnda1 = <Componente>[
  Componente(
    'ss-async-body',
    'SsAsyncBody',
    'Corpo de tela a partir de um AsyncValue (Riverpod): carregando, erro, sem conexão, vazio e dado.',
    comportamentos: [
      'Carregando mostra o esqueleto da lista (ou o loading que a tela passar).',
      'Erro mostra o SsErrorView com "Tentar de novo".',
      'Erro de rede (isOffline) troca o texto por "Sem conexão".',
      'isEmpty + empty mostram o estado vazio.',
      'Revalidar não pisca: o dado fica e um fio de progresso corre no topo.',
    ],
    estados: [
      Estado('carregando', 'carregando', (_) => _corpo(const AsyncLoading()), tamanho: _tela),
      Estado('erro', 'erro', (_) => _corpo(AsyncError(Exception('x'), StackTrace.empty)), tamanho: _tela),
      Estado(
        'offline',
        'sem conexão',
        (_) => _corpo(AsyncError(Exception('rede'), StackTrace.empty), offline: (_) => true),
        tamanho: _tela,
      ),
      Estado('vazio', 'vazio', (_) => _corpo(const AsyncData([])), tamanho: _tela),
      Estado('dados', 'dados', (_) => _corpo(const AsyncData(_itens)), tamanho: _tela),
      Estado('revalidando', 'revalidando', (_) => _corpo(_revalidando), tamanho: _tela, aguarde: 300),
    ],
  ),
  Componente(
    'ss-inline-async',
    'SsInlineAsync',
    'O mesmo do SsAsyncBody para uma seção dentro de uma lista que já rola: compacto, sem Expanded.',
    comportamentos: [
      'Carregando é um bloco-fantasma da altura da seção.',
      'Erro vira uma linha com o texto e "Tentar de novo".',
      'Vazio mostra o widget empty (ou nada).',
    ],
    estados: [
      for (final (slug, titulo, v) in [
        ('carregando', 'carregando', const AsyncLoading<String>()),
        ('erro', 'erro', AsyncError<String>(Exception('x'), StackTrace.empty)),
        ('dados', 'dados', const AsyncData('3 pedidos para entregar hoje')),
      ])
        Estado(
          slug,
          titulo,
          (_) => _pad(
            SsInlineAsync<String>(
              value: v,
              onRetry: _nada,
              data: (t) => SsListItem(icon: Icons.local_shipping_outlined, title: t),
            ),
          ),
          tamanho: const Size(360, 110),
        ),
    ],
  ),
  Componente(
    'ss-pull-to-refresh',
    'SsPullToRefresh',
    'Puxar para atualizar que funciona com lista curta, na cor da marca, com o brilho de aurora no topo.',
    comportamentos: [
      'Força a rolagem sempre: puxa mesmo com 2 itens ou estado vazio.',
      'Enquanto puxa, um brilho de aurora acende no topo na medida do arraste.',
      'Ao disparar dá um toque firme (haptic) e o brilho pulsa leve até terminar.',
      'Com menos movimento, o brilho fica parado.',
    ],
    estados: [
      Estado(
        'parado',
        'parado',
        (_) => SsPullToRefresh(onRefresh: _nadaAsync, child: _lista(_itens.take(2).toList())),
        tamanho: const Size(360, 240),
      ),
    ],
  ),
  Componente(
    'ss-paged-list',
    'SsPagedList · SsLoadMore',
    'Lista paginada com rolagem infinita e rodapé SsLoadMore (carregando, "Carregar mais", "Fim da lista").',
    comportamentos: [
      'Pede a próxima página sozinha a 400 px do fim.',
      'Se a página falhar, para de insistir e deixa o "Carregar mais".',
      'Com onRefresh, ganha o SsPullToRefresh.',
      'Padding de lista que respeita a barra do sistema (safeListPadding).',
    ],
    estados: [
      Estado(
        'tem-mais',
        'tem mais',
        (_) => SsPagedList<String>(
          items: _itens,
          hasMore: true,
          onLoadMore: _nadaAsync,
          itemBuilder: (_, t) => SsListItem(icon: Icons.receipt_long_outlined, title: t),
        ),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'fim',
        'fim da lista',
        (_) => SsPagedList<String>(
          items: _itens,
          hasMore: false,
          onLoadMore: _nadaAsync,
          itemBuilder: (_, t) => SsListItem(icon: Icons.receipt_long_outlined, title: t),
        ),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'rodape-carregando',
        'rodapé carregando',
        (_) => _pad(const SsLoadMore(hasMore: true, loading: true)),
        tamanho: const Size(360, 88),
      ),
      Estado(
        'rodape-mais',
        'rodapé "Carregar mais"',
        (_) => _pad(const SsLoadMore(hasMore: true, onLoadMore: _nada)),
        tamanho: const Size(360, 88),
      ),
    ],
  ),
  Componente(
    'ss-confirm',
    'showSsConfirm · showSsConfirmIrreversible · SsConfirmDialog',
    'Pergunta sim/não com botões empilhados; a versão irreversível pede para digitar a palavra.',
    comportamentos: [
      'Devolve true só se confirmou (fechar fora conta como não).',
      'danger pinta a confirmação de vermelho e a bolha do ícone.',
      'Irreversível: "Confirmar" só libera depois de digitar a palavra (sem diferenciar maiúscula).',
    ],
    estados: [
      Estado(
        'normal',
        'normal',
        (_) => const SsConfirmDialog(
          title: 'Enviar o pedido?',
          message: 'O cliente recebe o PDF por e-mail.',
          icon: Icons.send_outlined,
          confirmLabel: 'Enviar',
        ),
        tamanho: _dialogo,
      ),
      Estado(
        'perigo',
        'perigo',
        (_) => const SsConfirmDialog(
          title: 'Excluir o pedido 1042?',
          message: 'Ele sai da carteira e dos relatórios.',
          icon: Icons.delete_outline,
          confirmLabel: 'Excluir',
          danger: true,
        ),
        tamanho: _dialogo,
      ),
      Estado(
        'irreversivel',
        'irreversível',
        (_) => const SsConfirmDialog(
          title: 'Zerar todos os dados?',
          message: 'Não tem volta: pedidos, clientes e títulos somem.',
          icon: Icons.warning_amber_rounded,
          danger: true,
          word: 'APAGAR',
        ),
        tamanho: const Size(360, 540),
      ),
    ],
  ),
  Componente(
    'ss-prompt',
    'showSsPrompt · SsPromptDialog',
    'Pede um texto curto (nome de lista, de local) com validação.',
    comportamentos: [
      'Devolve o texto aparado; cancelar ou vazio devolve null.',
      'validator mostra o erro embaixo do campo e segura o "Salvar".',
      'Enter no teclado salva.',
    ],
    estados: [
      Estado(
        'padrao',
        'padrão',
        (_) => const SsPromptDialog(title: 'Nova lista', label: 'Nome da lista', initial: 'Mercado do mês'),
        tamanho: _dialogo,
      ),
    ],
  ),
  Componente(
    'ss-run-blocking',
    'ssRunBlocking · SsBlockingIndicator',
    'Bloqueia a tela com spinner e texto enquanto uma tarefa roda.',
    comportamentos: [
      'Voltar e tocar fora não fecham.',
      'Sempre fecha no fim, com sucesso ou erro; devolve o resultado ou repassa o erro.',
      'Leitor de tela anuncia o texto.',
    ],
    estados: [
      Estado(
        'padrao',
        'padrão',
        (_) => const ColoredBox(
          color: Colors.black54,
          child: SsBlockingIndicator(label: 'Salvando o pedido…'),
        ),
        tamanho: const Size(360, 200),
      ),
    ],
  ),
  Componente(
    'ss-unsaved-guard',
    'SsUnsavedGuard',
    'Em volta de um formulário: com alteração não salva, voltar pergunta antes de descartar.',
    comportamentos: [
      'Sem alteração (dirty falso), volta direto.',
      'Com alteração, abre "Descartar as alterações?" (perigo); só sai se confirmar.',
    ],
    estados: [
      Estado(
        'pergunta',
        'pergunta',
        (_) => const SsConfirmDialog(
          title: 'Descartar as alterações?',
          message: 'O que você mudou aqui ainda não foi salvo.',
          confirmLabel: 'Descartar',
          cancelLabel: 'Continuar editando',
          danger: true,
        ),
        tamanho: _dialogo,
      ),
    ],
  ),
  Componente(
    'ss-image-source',
    'showSsImageSource · SsImageSourcePicker',
    'Folha "Tirar foto / Escolher da galeria / Remover"; devolve a escolha e o app chama o image_picker.',
    comportamentos: [
      'Tocar numa opção fecha a folha devolvendo SsImageSource.',
      'allowRemove acrescenta "Remover foto" em vermelho.',
      'Fechar sem escolher devolve null.',
    ],
    estados: [
      for (final remover in [false, true])
        Estado(
          remover ? 'com-remover' : 'padrao',
          remover ? 'com remover' : 'padrão',
          (ctx) => Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: SsColors.of(ctx).surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
              child: SsSheet(
                title: 'Foto do produto',
                icon: Icons.image_outlined,
                child: SsImageSourcePicker(allowRemove: remover),
              ),
            ),
          ),
          tamanho: Size(360, remover ? 360 : 290),
        ),
    ],
  ),
  Componente(
    'ss-sheet',
    'showSsSheet · SsSheet',
    'Folha de baixo da suíte: alça, raio 26, área segura, sobe com o teclado e rola se passar da tela.',
    comportamentos: [
      'title monta o SsSheetHeader; child é o corpo, sem Scaffold.',
      'dismissible falso trava arrastar e tocar fora.',
      'Acompanha o teclado (viewInsets) e rola quando o conteúdo é alto.',
    ],
    estados: [
      Estado(
        'padrao',
        'padrão',
        (ctx) => Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: SsColors.of(ctx).surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
            child: const SsSheet(
              title: 'Filtrar pedidos',
              subtitle: 'Escolha o período e a situação.',
              icon: Icons.tune_rounded,
              child: Text('Corpo da folha'),
            ),
          ),
        ),
        tamanho: const Size(360, 220),
      ),
    ],
  ),
  Componente(
    'ss-sheet-header',
    'SsSheetHeader',
    'Cabeçalho de folha ou formulário: ícone num quadrado tonal, título e uma linha de ajuda.',
    comportamentos: ['Ícone na cor da marca (ou tone).', 'Marcado como cabeçalho para leitor de tela.'],
    estados: [
      Estado(
        'padrao',
        'padrão',
        (_) =>
            _pad(const SsSheetHeader('Novo cliente', subtitle: 'Só o nome é obrigatório.', icon: Icons.person_add_alt)),
      ),
      Estado(
        'perigo',
        'com tone',
        (_) => _pad(
          const SsSheetHeader(
            'Excluir conta',
            subtitle: 'Seus dados somem em 30 dias.',
            icon: Icons.delete_outline,
            tone: AppColors.danger,
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-offline-banner',
    'SsOfflineBanner',
    'Faixa fina no topo que avisa que a tela mostra o que já foi baixado, e "De volta online" quando a rede volta.',
    comportamentos: [
      'Desce com mola (380 ms) quando offline vira true.',
      'Ao voltar a rede, mostra "De volta online" em verde por 2 s e recolhe.',
      'Leitor de tela anuncia a mudança (liveRegion); ícone junto com a cor.',
      'Com menos movimento, aparece e some sem animar.',
    ],
    estados: [
      Estado('offline', 'sem conexão', (_) => const _OfflineDemo(volta: false), tamanho: const Size(360, 200)),
      Estado('volta', 'de volta online', (_) => const _OfflineDemo(volta: true), tamanho: const Size(360, 200)),
    ],
  ),
  Componente(
    'ss-undo',
    'showSsUndo · contagem do desfazer',
    'Aviso com "Desfazer" cuja borda se esvazia durante o tempo (5 s); devolve se a pessoa desfez.',
    comportamentos: [
      'Devolve true se tocou em "Desfazer"; quem chama só exclui de verdade com false.',
      'A borda fina na cor da marca anda até sumir junto com o aviso.',
      'Outro aviso no lugar conta como não desfeito.',
      'Com menos movimento, a borda fica parada.',
    ],
    estados: [
      for (final (slug, titulo, ms) in [('inicio', 'início', 50), ('meio', 'na metade', 2500)])
        Estado(
          slug,
          titulo,
          (_) => _pad(
            const SsToast(
              'Pedido excluído',
              icon: Icons.delete_outline,
              actionLabel: 'Desfazer',
              onAction: _nada,
              countdown: Duration(seconds: 5),
            ),
          ),
          aguarde: ms,
        ),
    ],
  ),
];
