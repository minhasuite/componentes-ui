// Entradas do catálogo da onda2: campos de formulário, stepper e picker.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);
const _campo = Size(360, 120);
const _tela = Size(360, 780);
const _data = Size(360, 150);

/// Form que valida logo depois do 1º quadro (mostra o erro e a sacudida).
class _Invalido extends StatefulWidget {
  const _Invalido(this.child);
  final Widget child;

  @override
  State<_Invalido> createState() => _InvalidoState();
}

class _InvalidoState extends State<_Invalido> {
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _form.currentState?.validate());
  }

  @override
  Widget build(BuildContext context) => Form(key: _form, child: widget.child);
}

/// Stepper com estado próprio (o catálogo não tem pai que guarde o valor).
class _Stepper extends StatefulWidget {
  const _Stepper(this.inicio, {this.max = 10, this.decimals = 0, this.step = 1, this.unit, this.label});
  final num inicio;
  final num max;
  final int decimals;
  final num step;
  final String? unit;
  final String? label;

  @override
  State<_Stepper> createState() => _StepperState();
}

class _StepperState extends State<_Stepper> {
  late num v = widget.inicio;

  @override
  Widget build(BuildContext context) => SsStepper(
    value: v,
    max: widget.max,
    step: widget.step,
    decimals: widget.decimals,
    unit: widget.unit,
    label: widget.label,
    onChanged: (n) => setState(() => v = n),
  );
}

const _ufs = {
  'SP': 'São Paulo',
  'RJ': 'Rio de Janeiro',
  'MG': 'Minas Gerais',
  'PR': 'Paraná',
  'SC': 'Santa Catarina',
  'RS': 'Rio Grande do Sul',
  'BA': 'Bahia',
  'PE': 'Pernambuco',
  'CE': 'Ceará',
  'GO': 'Goiás',
};
const _clientes = ['Mercado São João', 'Padaria Pão de Açúcar', 'Açougue Boi Gordo', 'Farmácia Saúde'];

Widget _folha(Widget child) => Align(alignment: Alignment.bottomCenter, child: child);

final catalogoOnda2 = <Componente>[
  Componente(
    'ss-text-field',
    'SsTextField',
    'Campo de texto do formulário: rótulo acima, fundo de campo e anel com halo da marca no foco.',
    comportamentos: const [
      'No foco o fundo clareia e ganha anel e halo na cor da marca.',
      'Valida ao sair do campo; depois do primeiro erro, valida a cada letra.',
      'O erro aparece embaixo com ícone e o campo dá uma sacudida curta no envio do formulário.',
      'É um TextFormField: funciona dentro de Form.',
      'suffixText põe a unidade ("kg") depois do valor; maxLength limita sem contador; textCapitalization para nome e título.',
    ],
    estados: [
      Estado(
        'unidade',
        'com unidade no fim',
        (_) => _pad(const SsTextField(label: 'Peso', initialValue: '82,5', suffixText: 'kg')),
        tamanho: _campo,
      ),
      Estado(
        'vazio',
        'vazio',
        (_) => _pad(const SsTextField(label: 'Nome', hint: 'Como aparece no pedido')),
        tamanho: _campo,
      ),
      Estado(
        'preenchido',
        'preenchido com ícone',
        (_) =>
            _pad(const SsTextField(label: 'E-mail', icon: Icons.mail_outline_rounded, initialValue: 'ana@loja.com.br')),
        tamanho: _campo,
      ),
      Estado(
        'foco',
        'em foco',
        (_) => _pad(const SsTextField(label: 'Nome', hint: 'Como aparece no pedido', autofocus: true)),
        tamanho: _campo,
      ),
      Estado(
        'erro',
        'erro',
        (_) => _pad(
          const _Invalido(SsTextField(label: 'Nome', hint: 'Como aparece no pedido', validator: SsValidators.required)),
        ),
        tamanho: const Size(360, 140),
        aguarde: 700,
      ),
    ],
  ),
  Componente(
    'ss-money-field',
    'SsMoneyField',
    'Dinheiro em centavos com máscara de R\$ que cresce da direita, em DM Mono.',
    comportamentos: const [
      'Digita só números: 0,00 → 0,05 → 0,50 → 5,00.',
      'Devolve os centavos (int) a cada mudança.',
      'Com keypad, o toque abre o teclado de valor próprio no lugar do teclado do sistema.',
    ],
    estados: [
      Estado(
        'vazio',
        'vazio',
        (_) => _pad(SsMoneyField(label: 'Valor', cents: null, onChanged: (_) {})),
        tamanho: _campo,
      ),
      Estado(
        'valor',
        'com valor',
        (_) => _pad(SsMoneyField(label: 'Valor', cents: 123456, onChanged: (_) {})),
        tamanho: _campo,
      ),
      Estado(
        'erro',
        'erro',
        (_) => _pad(
          _Invalido(SsMoneyField(label: 'Valor', cents: null, onChanged: (_) {}, validator: SsValidators.money)),
        ),
        tamanho: const Size(360, 140),
        aguarde: 700,
      ),
    ],
  ),
  Componente(
    'ss-amount-keypad',
    'showSsAmountKeypad',
    'Folha com o valor grande em DM Mono e um teclado numérico próprio.',
    comportamentos: const [
      'Teclas 1–9, 00, 0 e apagar; o valor cresce da direita.',
      'A tecla encolhe no toque e vibra leve.',
      'Segurar o apagar zera o valor.',
      'Confirmar devolve os centavos; fechar devolve nulo.',
    ],
    estados: [
      Estado(
        'valor',
        'com valor',
        (_) => _folha(
          SsSheet(
            title: 'Valor',
            child: SsAmountKeypad(initial: 12350, onConfirm: (_) {}),
          ),
        ),
        tamanho: const Size(360, 520),
      ),
    ],
  ),
  Componente(
    'ss-date-field',
    'SsDateField',
    'Data por atalhos em chips; o calendário só abre em "Outra…".',
    comportamentos: const [
      'Atalhos: Hoje, Amanhã e o próximo dia útil (Sex, ou Seg quando amanhã já é sexta ou fim de semana).',
      'Atalhos fora de firstDate/lastDate somem.',
      '"Outra…" abre o calendário em pt-BR e passa a mostrar a data escolhida.',
      'Com clearable, um ✕ limpa a data.',
    ],
    estados: [
      Estado(
        'hoje',
        'hoje',
        (_) => _pad(SsDateField(label: 'Vencimento', value: DateTime.now(), onChanged: (_) {})),
        tamanho: _data,
      ),
      Estado(
        'outra',
        'outra data, com limpar',
        (_) => _pad(SsDateField(label: 'Vencimento', value: DateTime(2027, 3, 15), clearable: true, onChanged: (_) {})),
        tamanho: _data,
      ),
      Estado(
        'vazio',
        'vazio',
        (_) => _pad(SsDateField(label: 'Vencimento', value: null, onChanged: (_) {})),
        tamanho: _data,
      ),
    ],
  ),
  Componente(
    'ss-date-time-field',
    'SsDateTimeField',
    'Os atalhos de data do SsDateField com um chip de hora.',
    comportamentos: const [
      'O chip de hora abre o relógio do sistema.',
      'Trocar o dia mantém a hora (9:00 quando ainda não há).',
    ],
    estados: [
      Estado('com-hora', 'amanhã às 14:30', (_) {
        final a = DateTime.now().add(const Duration(days: 1));
        return _pad(
          SsDateTimeField(label: 'Visita', value: DateTime(a.year, a.month, a.day, 14, 30), onChanged: (_) {}),
        );
      }, tamanho: _data),
    ],
  ),
  Componente(
    'ss-choice-field',
    'SsChoiceField',
    'Escolha de uma opção num campo que abre uma folha com a lista.',
    comportamentos: const [
      'A folha marca a opção atual com ✓.',
      'Com mais de 8 opções aparece a busca, que ignora acento.',
      'É um FormField: aceita validator dentro de Form.',
    ],
    estados: [
      Estado(
        'vazio',
        'vazio',
        (_) => _pad(SsChoiceField<String>(label: 'Estado', value: null, options: _ufs, onChanged: (_) {})),
        tamanho: _campo,
      ),
      Estado(
        'escolhido',
        'escolhido',
        (_) => _pad(
          SsChoiceField<String>(
            label: 'Estado',
            icon: Icons.map_outlined,
            value: 'PR',
            options: _ufs,
            onChanged: (_) {},
          ),
        ),
        tamanho: _campo,
      ),
      Estado(
        'erro',
        'erro',
        (_) => _pad(
          _Invalido(
            SsChoiceField<String>(
              label: 'Estado',
              value: null,
              options: _ufs,
              onChanged: (_) {},
              validator: SsValidators.required,
            ),
          ),
        ),
        tamanho: const Size(360, 140),
      ),
      Estado(
        'folha',
        'folha com busca',
        (_) => _folha(
          SsSheet(
            title: 'Estado',
            child: SsChoiceList<String>(options: _ufs, selected: 'PR', onSelect: (_) {}),
          ),
        ),
        tamanho: _tela,
      ),
    ],
  ),
  Componente(
    'ss-switch-row',
    'SsSwitchRow',
    'Linha de ajuste ligado/desligado com título, subtítulo e Switch na cor da marca.',
    comportamentos: const [
      'Tocar em qualquer lugar da linha alterna.',
      'Vibra de leve ao alternar.',
      'onChanged nulo desabilita.',
    ],
    estados: [
      for (final (slug, v) in [('ligado', true), ('desligado', false)])
        Estado(
          slug,
          slug,
          (_) => _pad(
            SsSwitchRow(title: 'Lembrar vencimentos', subtitle: 'Avisa um dia antes', value: v, onChanged: (_) {}),
          ),
        ),
      Estado(
        'desabilitado',
        'desabilitado',
        (_) => _pad(
          const SsSwitchRow(title: 'Lembrar vencimentos', subtitle: 'Só no plano Pro', value: false, onChanged: null),
        ),
      ),
    ],
  ),
  Componente(
    'ss-stepper',
    'SsStepper',
    'Ajuste numérico − valor +, com o número em DM Mono que rola na direção da mudança.',
    comportamentos: const [
      'O número novo entra deslizando de baixo quando sobe e de cima quando desce.',
      'Segurar um botão repete cada vez mais rápido.',
      'No limite o botão apaga e vibra forte ("bateu").',
      'Tocar no número abre para digitar.',
      'label põe o rótulo pequeno em maiúsculas em cima (e no leitor de tela).',
    ],
    estados: [
      Estado('meio', 'no meio', (_) => _pad(const SizedBox(width: 200, child: _Stepper(3, unit: 'pessoas')))),
      Estado('minimo', 'no mínimo', (_) => _pad(const SizedBox(width: 200, child: _Stepper(0)))),
      Estado(
        'decimal',
        'decimal no máximo',
        (_) => _pad(
          const SizedBox(
            width: 200,
            child: _Stepper(20, max: 20, decimals: 1, step: .5, unit: 'kg', label: 'Peso'),
          ),
        ),
        tamanho: const Size(360, 120),
      ),
    ],
  ),
  Componente(
    'ss-picker',
    'showSsPicker',
    'Folha alta de busca e escolha (cliente, produto, lugar) com a busca fixa no topo.',
    comportamentos: const [
      'Ocupa até 90% da tela; a busca fica fixa e a lista rola.',
      'Com load, busca no servidor com debounce de 300 ms; com items, filtra na hora sem acento.',
      'Mostra carregando, vazio e erro (com tentar de novo).',
      'Tocar num item fecha e devolve o item.',
    ],
    estados: [
      Estado(
        'lista',
        'lista',
        (_) => SsPickerSheet<String>(title: 'Cliente', items: _clientes, onSelect: (_) {}),
        tamanho: _tela,
      ),
      Estado(
        'carregando',
        'carregando',
        (_) => SsPickerSheet<String>(title: 'Cliente', load: (_) => Completer<List<String>>().future, onSelect: (_) {}),
        tamanho: _tela,
      ),
      Estado(
        'vazio',
        'vazio',
        (_) => SsPickerSheet<String>(title: 'Cliente', items: const [], emptyText: 'Nenhum cliente', onSelect: (_) {}),
        tamanho: _tela,
      ),
      Estado(
        'erro',
        'erro',
        (_) => SsPickerSheet<String>(title: 'Cliente', load: (_) async => throw Exception('rede'), onSelect: (_) {}),
        tamanho: _tela,
      ),
    ],
  ),
];
