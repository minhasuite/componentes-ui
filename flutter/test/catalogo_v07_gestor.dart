// Entradas do catálogo da v0.7 pedidas pela migração do meu-gestor.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalogo.dart';

/// O sliver dentro de uma rolagem de altura fixa (o catálogo desenha numa caixa).
Widget _rolagem(Widget sliver) => SizedBox(height: 220, child: CustomScrollView(slivers: [sliver]));

const _tamanho = Size(360, 220);

Widget _linha(String t) => SsListItem(icon: Icons.inbox_outlined, title: t);

final catalogoV07Gestor = <Componente>[
  Componente(
    'ss-async-sliver',
    'SsAsyncSliver',
    'O SsAsyncBody como sliver: lista de tela com SsScreenHeader que carrega, falha ou fica vazia sem tirar o título.',
    comportamentos: [
      'Com dado, os itens de data viram um SliverList com o padding dado.',
      'Revalidando com dado anterior: a lista fica e um fio de 2 px aparece no topo (não pisca).',
      'Carregando, erro ou vazio ocupam o resto da tela abaixo do cabeçalho (SliverFillRemaining).',
      'Erro: SsErrorView com "Tentar de novo"; isOffline troca o texto pelo de sem conexão.',
      'O puxar para atualizar do SsScreenHeader continua funcionando em todos os estados.',
    ],
    estados: [
      Estado(
        'dados',
        'lista de itens',
        tamanho: _tamanho,
        (_) => _rolagem(
          SsAsyncSliver<List<String>>(
            value: const AsyncValue.data(['Conferir nota', 'Abrir a loja']),
            data: (l) => [for (final t in l) _linha(t)],
          ),
        ),
      ),
      Estado(
        'carregando',
        'esqueleto no lugar da lista',
        tamanho: _tamanho,
        (_) => _rolagem(SsAsyncSliver<List<String>>(value: const AsyncValue.loading(), data: (_) => const [])),
      ),
      Estado(
        'vazio',
        'isEmpty + empty',
        tamanho: _tamanho,
        (_) => _rolagem(
          SsAsyncSliver<List<String>>(
            value: const AsyncValue.data([]),
            isEmpty: (l) => l.isEmpty,
            empty: const SsEmptyState(icon: Icons.inbox_outlined, title: 'Nada por aqui', compact: true),
            data: (_) => const [],
          ),
        ),
      ),
      Estado(
        'erro',
        'mensagem e tentar de novo',
        tamanho: _tamanho,
        (_) => _rolagem(
          SsAsyncSliver<List<String>>(
            value: AsyncValue.error(Exception('falhou'), StackTrace.empty),
            onRetry: () {},
            data: (_) => const [],
          ),
        ),
      ),
    ],
  ),
];
