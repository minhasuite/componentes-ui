// Estados e comportamentos da v0.20 (o que o minhas-vendas e o meu-gestor
// acharam ao migrar para 100% de componentização): peça nova em [catalogoV20]
// e os extras das que já existiam (por slug) em [comV20].
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

final catalogoV20 = <Componente>[
  Componente(
    'ss-radio-group',
    'SsRadioGroup',
    'Grupo de opções (rádio) com o rótulo em cima; a marcada vem do value (sem model). Par do f.ss_radio_buttons(checked:).',
    comportamentos: [
      'Em linha (quebra quando não cabe) ou empilhado (inline: false).',
      'Bolinha que engrossa a borda na cor da marca ao marcar (180 ms; nada com reduzir movimento).',
      'Cada opção tem alvo de 48 e é lida como rádio de um grupo exclusivo, com marcado/desmarcado.',
      'É um FormField: validator mostra o erro embaixo; onChanged nulo desabilita (meia opacidade).',
    ],
    estados: [
      Estado(
        'linha',
        'em linha',
        (_) => _pad(
          SsRadioGroup<String>(
            label: 'Tipo de cliente',
            value: 'pj',
            options: const {'pf': 'Pessoa física', 'pj': 'Empresa'},
            onChanged: (_) {},
          ),
        ),
        tamanho: const Size(360, 120),
      ),
      Estado(
        'empilhado',
        'empilhado e desabilitado',
        (_) => _pad(
          const SsRadioGroup<int>(
            label: 'Plano',
            value: 2,
            options: {1: 'Mensal', 2: 'Anual', 3: 'Vitalício'},
            onChanged: null,
            inline: false,
          ),
        ),
        tamanho: const Size(360, 220),
      ),
    ],
  ),
  Componente(
    'ss-sticky-action-bar',
    'SsStickyActionBar',
    'Barra fixa de ações embaixo da tela com resumo livre à esquerda (ou uma mensagem) e botões à direita. Par do Ss::StickyActionBarComponent.',
    comportamentos: [
      'summary: conteúdo livre ("3 itens · R\$ 120,00"); sem ele, message: em texto.',
      'Fio no topo, fundo de superfície, área segura embaixo; respiros da densidade.',
      'visible: false desce e some com a mola (formulário sem alteração) e deixa de receber toque.',
      'O resumo é região viva: o leitor de tela ouve quando o total muda.',
    ],
    estados: [
      Estado(
        'resumo',
        'resumo do pedido',
        (_) => Align(
          alignment: Alignment.bottomCenter,
          child: SsStickyActionBar(
            summary: const Row(spacing: 8, children: [Text('3 itens'), SsAmount(r'R$ 120,00', size: 18)]),
            actions: [SsButton(label: 'Fechar pedido', expand: false, onPressed: _nada)],
          ),
        ),
        tamanho: const Size(390, 110),
      ),
      Estado(
        'mensagem',
        'alterações não salvas',
        (_) => Align(
          alignment: Alignment.bottomCenter,
          child: SsStickyActionBar(
            message: 'Alterações não salvas',
            actions: [
              SsButton.ghost(label: 'Cancelar', expand: false, small: true, onPressed: _nada),
              SsButton(label: 'Salvar', expand: false, small: true, onPressed: _nada),
            ],
          ),
        ),
        tamanho: const Size(390, 100),
      ),
    ],
  ),
  Componente(
    'ss-repeater',
    'SsRepeater',
    'Linhas repetíveis de formulário (itens, telefones, parcelas) com o × de tirar e "Adicionar" embaixo. Par do Ss::RepeaterComponent + ss-repeater.',
    comportamentos: [
      'A lista é do app: onAdd acrescenta e onRemove(i) tira; o widget só desenha.',
      'minItems esconde o × quando sobram só essas linhas.',
      'O × é lido "Remover linha 2"; o botão de adicionar usa o texto addRow (pt/en/es).',
      'v0.20.3: header: põe o cabeçalho uma vez (na largura das linhas, com a coluna do ×) e o × fica no meio da linha; flex: e SsRepeater.cells alinham as colunas; os campos usam hideLabel: true.',
    ],
    estados: [
      Estado(
        'itens',
        'dois telefones',
        (_) => _pad(
          SsRepeater(
            itemCount: 2,
            minItems: 1,
            itemBuilder: (_, i) => SsTextField(label: 'Telefone ${i + 1}', initialValue: '(85) 9876$i-432$i'),
            onAdd: _nada,
            onRemove: (_) {},
          ),
        ),
        tamanho: const Size(360, 260),
      ),
      Estado(
        'cabecalho',
        'cabeçalho único (v0.20.3)',
        (_) => _pad(
          SsRepeater(
            itemCount: 2,
            header: const ['Produto', 'Qtd', 'Total'],
            flex: const [4, 1, 2],
            itemBuilder: (_, i) => SsRepeater.cells(
              [
                SsTextField(label: 'Produto', hideLabel: true, initialValue: i == 0 ? 'Arroz 5 kg' : 'Feijão 1 kg'),
                SsTextField(label: 'Qtd', hideLabel: true, initialValue: '${i + 1}'),
                Text(i == 0 ? r'R$ 25,90' : r'R$ 17,80', textAlign: TextAlign.end),
              ],
              flex: const [4, 1, 2],
            ),
            onAdd: _nada,
            onRemove: (_) {},
          ),
        ),
        tamanho: const Size(420, 290),
      ),
    ],
  ),
  Componente(
    'ss-link-text',
    'SsLinkText',
    'Parágrafo com links no meio (String e SsTextLink misturados); o link é texto de verdade e quebra junto da linha. Par do a.ss-link.',
    comportamentos: [
      'Link na cor da marca em 700; o resto em 12/500 no muted (style: troca).',
      'Tocar no link chama o onTap; os reconhecedores de toque são do widget.',
      'SsTextLink(external: true) diz "abre fora do app" ao leitor de tela.',
    ],
    estados: [
      Estado(
        'padrao',
        'link no meio do texto',
        (_) => _pad(
          SsLinkText([
            'Ao criar a conta você concorda com os ',
            SsTextLink('termos', onTap: _nada),
            ' e a ',
            SsTextLink('privacidade', onTap: _nada),
            '.',
          ]),
        ),
        tamanho: const Size(360, 80),
      ),
    ],
  ),
  Componente(
    'ss-terms-notice',
    'SsTermsNotice',
    '"Ao continuar, você concorda com os Termos de uso e a Política de privacidade." com os dois links, em pt/en/es. Par do Ss::TermsNoticeComponent.',
    comportamentos: [
      'onOpen(url) recebe a URL tocada (o app abre; o pacote não depende do url_launcher).',
      'text: troca a frase, com {terms} e {privacy} onde entram os links.',
      'Centralizado por padrão (textAlign:).',
    ],
    estados: [
      Estado(
        'padrao',
        'no login',
        (_) => _pad(SsTermsNotice(termsUrl: '/termos', privacyUrl: '/privacidade', onOpen: (_) {})),
        tamanho: const Size(360, 80),
      ),
    ],
  ),
  Componente(
    'ss-editable-value',
    'SsEditableValue',
    'Valor que se edita ao toque: rótulo pequeno, o valor em DM Mono e "editar" na cor da marca; o toque abre a edição do app. Par do Ss::EditableValueComponent.',
    comportamentos: [
      'Um nó só para o leitor de tela: "novo: R\$ 12,90, Editar".',
      'Alvo de 48; alinhado à direita (alignment: start para a esquerda).',
      'Sem onEdit some o "editar" e o toque.',
    ],
    estados: [
      Estado(
        'padrao',
        'preço novo',
        (_) => _pad(
          Align(
            alignment: Alignment.centerRight,
            child: SsEditableValue(label: 'novo', value: r'R$ 12,90', onEdit: _nada),
          ),
        ),
        tamanho: const Size(240, 110),
      ),
    ],
  ),
];

List<Componente> comV20(List<Componente> base) => [
  for (final c in base)
    if (_v20[c.slug] case (final comp, final est))
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

final _colunas = [
  const SsDataColumn('Cliente'),
  const SsDataColumn('Total', numeric: true),
  const SsDataColumn('Cidade'),
  const SsDataColumn('Vendedor'),
];

final Map<String, (List<String>, List<Estado>)> _v20 = {
  'ss-text-field': (
    [
      'v0.20: hideLabel: true deixa o rótulo só para o leitor de tela (par do f.ss_*(hide_label: true)).',
      'v0.20: mask: SsMask.document (CPF ou CNPJ, inclusive o alfanumérico), SsMask.phone, SsMask.cep formata enquanto digita e põe o teclado numérico (par do ss-mask).',
    ],
    [
      Estado(
        'mascara',
        'CPF/CNPJ, telefone e CEP',
        (_) => _pad(
          const Column(
            spacing: 10,
            children: [
              SsTextField(label: 'CPF ou CNPJ', initialValue: '11.222.333/0001-81', mask: SsMask.document),
              SsTextField(label: 'Telefone', initialValue: '(85) 98765-4321', mask: SsMask.phone),
              SsTextField(label: 'Buscar', hideLabel: true, hint: 'Rótulo só no leitor de tela'),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  'ss-button': (
    [
      'v0.20: SsButton.ghost(tone: SsTone.danger) é o "Excluir" discreto: fundo de campo e texto no tom (par do ButtonComponent(variant: :ghost, tone: :danger)).',
    ],
    [
      Estado(
        'ghost-perigo',
        'discreto de perigo',
        (_) => _pad(
          Row(
            spacing: 10,
            children: [
              SsButton.ghost(
                label: 'Excluir',
                icon: Icons.delete_outline_rounded,
                tone: SsTone.danger,
                expand: false,
                onPressed: _nada,
              ),
              SsButton.ghost(label: 'Cancelar', expand: false, onPressed: _nada),
            ],
          ),
        ),
        tamanho: const Size(360, 90),
      ),
    ],
  ),
  'ss-list-item': (
    [
      'v0.20: subtitleTone:/valueTone: pintam o subtítulo e o valor no tom (par do Ss::ListItemComponent(subtitle_tone:, value_tone:)).',
    ],
    [
      Estado(
        'tons',
        'vence hoje · pago',
        (_) => _pad(
          const Column(
            children: [
              SsListItem(
                title: 'Boleto 1234',
                subtitle: 'Vence hoje',
                subtitleTone: SsTone.danger,
                value: r'R$ 120,00',
                icon: Icons.receipt_long_rounded,
              ),
              SsListItem(
                title: 'Boleto 1233',
                subtitle: 'Pago',
                subtitleTone: SsTone.success,
                value: r'R$ 80,00',
                valueTone: SsTone.success,
                icon: Icons.receipt_long_rounded,
                dimmed: true,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
  'ss-kpi-card': (
    [
      'v0.20: valueTone: pinta o valor (saldo negativo em danger, meta batida em success); par do value_tone:. SsCardHeader(eyebrow:, eyebrowTone:) põe a sobrelinha em versalete em cima do título.',
    ],
    [
      Estado(
        'tom',
        'valor em tom e sobrelinha',
        (_) => _pad(
          const Column(
            spacing: 10,
            children: [
              SsKpiCard(
                label: 'Saldo do caixa',
                value: r'−R$ 1.250,00',
                valueTone: SsTone.danger,
                icon: Icons.account_balance_wallet_outlined,
              ),
              SsCard(
                child: SsCardHeader(
                  title: 'Ruptura em 3 produtos',
                  eyebrow: 'Estoque · urgente',
                  eyebrowTone: SsTone.danger,
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  'ss-data-table': (
    [
      'v0.20: stickyFirstColumn: rola de lado com a 1ª coluna parada quando as colunas não cabem (mínimo minColumnWidth).',
      'v0.20.4: stack: false mantém a tabela no celular (rola de lado; com stickyFirstColumn a 1ª fica parada) em vez de virar cartões.',
      'v0.20: footer: linha de total em negrito no fundo do campo (no celular, bloco no fim); flat: sem moldura de card; SsDataRow(dimmed:) apaga a linha; SsDataColumn(header:) troca o texto do cabeçalho por um widget.',
    ],
    [
      Estado(
        'total',
        'total, linha apagada e sem card',
        (_) => _pad(
          SsCard(
            padding: EdgeInsets.zero,
            child: SsDataTable(
              flat: true,
              stackBelow: 300,
              columns: _colunas,
              rows: [
                SsDataRow.text(['Ana', '10,00', 'Fortaleza', 'João']),
                SsDataRow.text(['Bia', '5,00', 'Sobral', 'Maria'], dimmed: true),
              ],
              footer: const [Text('Total'), Text('15,00')],
            ),
          ),
        ),
        tamanho: const Size(560, 240),
      ),
      Estado(
        'coluna-parada',
        '1ª coluna parada',
        (_) => _pad(
          SsDataTable(
            stickyFirstColumn: true,
            minColumnWidth: 140,
            stackBelow: 200,
            columns: _colunas,
            rows: [
              SsDataRow.text(['Ana', '10,00', 'Fortaleza', 'João']),
              SsDataRow.text(['Bia', '5,00', 'Sobral', 'Maria']),
            ],
          ),
        ),
        tamanho: const Size(360, 220),
      ),
      Estado(
        'sem-cartoes',
        'stack: false no celular (v0.20.4)',
        (_) => _pad(
          SsDataTable(
            stack: false,
            stickyFirstColumn: true,
            minColumnWidth: 56,
            columns: [
              for (final n in ['Pessoa', for (var d = 1; d <= 14; d++) '$d']) SsDataColumn(n),
            ],
            rows: [
              for (final p in ['Ana', 'Bia', 'Caio'])
                SsDataRow.text([p, for (var d = 1; d <= 14; d++) (d + p.length).isEven ? 'M' : 'T']),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  'ss-picker': (
    [
      'v0.20: actions: [SsPickerAction(icon:, tooltip:, onPressed:)] põe botões ao lado da busca; o onPressed devolve um item para fechar com ele (código lido) ou nulo para continuar aberto.',
    ],
    [
      Estado(
        'acao',
        'leitor de código ao lado da busca',
        (_) => SsPickerSheet<String>(
          title: 'Produto',
          items: const ['Arroz 5 kg', 'Feijão 1 kg', 'Café 500 g'],
          actions: [
            SsPickerAction(
              icon: Icons.qr_code_scanner_rounded,
              tooltip: 'Ler código de barras',
              onPressed: (_) => null,
            ),
          ],
          onSelect: (_) {},
        ),
        tamanho: const Size(360, 520),
      ),
    ],
  ),
  'ss-nav-bar': (
    [
      'v0.20: SsNavItem(badge:) põe a contagem no ícone (0 some, acima de 99 vira "99+"); o leitor de tela ouve "Cards: 3 novas, aba 2 de 4".',
    ],
    [
      Estado(
        'contagem',
        'contagem na aba',
        (_) => Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: SsNavBar(
            currentIndex: 0,
            onTap: (_) {},
            items: const [
              SsNavItem(Icons.home_outlined, 'Início', activeIcon: Icons.home_rounded),
              SsNavItem(Icons.inbox_outlined, 'Cards', badge: 3),
              SsNavItem(Icons.checklist_rounded, 'Checklist', badge: 120),
              SsNavItem(Icons.menu_rounded, 'Mais'),
            ],
          ),
        ),
        tamanho: const Size(390, 160),
      ),
    ],
  ),
};
