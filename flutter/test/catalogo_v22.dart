// v0.22: tela de entrada "Folhinha" ([catalogoV22]: ss-auth-folhinha), par do Ss::AuthLayoutComponent.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

final _dia = DateTime(2026, 11, 13);

List<Widget> _entrar() => [
  const SsTextField(label: 'E-mail', hint: 'voce@exemplo.com', keyboardType: TextInputType.emailAddress),
  const SizedBox(height: 14),
  const SsTextField(label: 'Senha', obscureText: true),
  const SizedBox(height: 18),
  SsButton(label: 'Entrar', onPressed: () {}),
];

final catalogoV22 = <Componente>[
  Componente(
    'ss-auth-folhinha',
    'SsAuthLayout.folhinha',
    'Tela de entrada "Folhinha": folhinha de parede com a data de hoje, o formulário do app no bloco e a faixa do produto na cor da marca. Par do Ss::AuthLayoutComponent.',
    comportamentos: [
      'variant: sheet (folha pendurada, padrão), wall (folhinha grande à esquerda e o formulário numa coluna; abaixo de 840 empilha) e pad (bloco de destacar, com a folha de amanhã por baixo).',
      'date: é o dia da folhinha (padrão hoje); domingo na cor de perigo. Mês e dia da semana do SsStrings (pt/en/es).',
      'O bloco é do app (SsTextField, SsButton, SsCallout, SsGoogleButton); título e números em AppTheme.display (Big Shoulders Display, empacotada).',
      'Na wall a folhinha grande fica fora do leitor de tela; o painel diz "Parte da MinhaSuite" (authPartOf).',
      'O construtor padrão do SsAuthLayout (halos e ícone) não muda.',
    ],
    estados: [
      Estado(
        'sheet',
        'sheet: entrar',
        (_) => SsAuthLayout.folhinha(
          product: 'Meu Gestor',
          tagline: 'A loja em dia, sem planilha.',
          title: 'Entrar',
          subtitle: 'no Meu Gestor',
          note: 'bom dia para organizar',
          date: _dia,
          children: _entrar(),
        ),
        tamanho: const Size(420, 860),
      ),
      Estado(
        'domingo',
        'sheet: domingo em vermelho',
        (_) => SsAuthLayout.folhinha(
          product: 'Meu Financeiro',
          title: 'Entrar',
          date: DateTime(2026, 11, 15),
          children: _entrar(),
        ),
        tamanho: const Size(420, 780),
      ),
      Estado(
        'wall',
        'wall: senha errada (largo)',
        (_) => SsAuthLayout.folhinha(
          product: 'Minhas Vendas',
          tagline: 'A venda não para.',
          title: 'Entrar',
          subtitle: 'no Minhas Vendas',
          variant: SsAuthVariant.wall,
          date: _dia,
          children: [
            const SsCallout(
              tone: SsTone.danger,
              title: 'E-mail ou senha não conferem.',
              message: 'Confira os dois ou use Esqueci a senha.',
            ),
            const SizedBox(height: 16),
            ..._entrar(),
          ],
        ),
        tamanho: const Size(1100, 760),
      ),
      Estado(
        'wall-celular',
        'wall: no celular, empilhada',
        (_) => SsAuthLayout.folhinha(
          product: 'Minhas Vendas',
          tagline: 'A venda não para.',
          title: 'Entrar',
          variant: SsAuthVariant.wall,
          date: _dia,
          children: _entrar(),
        ),
        tamanho: const Size(390, 1040),
      ),
      Estado(
        'pad',
        'pad: link enviado',
        (_) => SsAuthLayout.folhinha(
          product: 'Meu Financeiro',
          tagline: 'Seu dinheiro, sem susto.',
          title: 'Confira seu e-mail',
          subtitle: 'O link vale por 2 horas.',
          variant: SsAuthVariant.pad,
          date: _dia,
          children: [
            const SsCallout(
              tone: SsTone.success,
              title: 'Link enviado para ana.souza@exemplo.com.',
              message: 'Não chegou? Veja o spam ou envie de novo.',
            ),
            const SizedBox(height: 16),
            SsButton(label: 'Voltar para entrar', variant: SsButtonVariant.ghost, onPressed: () {}),
          ],
        ),
        tamanho: const Size(420, 760),
      ),
    ],
  ),
];
