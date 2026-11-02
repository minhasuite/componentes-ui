import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ss_async.dart';

/// O [SsAsyncBody] como sliver, para os `slivers` do `SsScreenHeader`: com
/// dado, os filhos de [data] numa lista com [padding] (revalidar mostra o fio
/// no topo, sem piscar); carregando, erro ou vazio ocupam o resto da tela
/// abaixo do cabeçalho (o título continua lá, e o puxar para atualizar também).
///
/// `SsScreenHeader(title: 'Pedidos', slivers: [SsAsyncSliver(value: v, data: (l) => [for (p in l) Linha(p)])])`
class SsAsyncSliver<T> extends StatelessWidget {
  const SsAsyncSliver({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
    this.loading,
    this.isEmpty,
    this.empty,
    this.isOffline,
    this.errorMessage,
  });

  final AsyncValue<T> value;

  /// Os itens da lista (cada um vira um filho do `SliverList`).
  final List<Widget> Function(T data) data;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;
  final Widget? loading;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final bool Function(Object error)? isOffline;
  final String Function(Object error)? errorMessage;

  @override
  Widget build(BuildContext context) {
    final v = value.valueOrNull;
    final vazio = value.hasValue && empty != null && (isEmpty?.call(value.requireValue) ?? false);
    if (!value.hasValue || vazio) {
      return SliverFillRemaining(
        child: SsAsyncBody<T>(
          value: value,
          data: (_) => const SizedBox.shrink(),
          onRetry: onRetry,
          loading: loading,
          isEmpty: isEmpty,
          empty: empty,
          isOffline: isOffline,
          errorMessage: errorMessage,
        ),
      );
    }
    final itens = data(v as T);
    return SliverMainAxisGroup(
      slivers: [
        if (value.isLoading)
          const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent)),
        SliverPadding(
          padding: padding,
          sliver: SliverList.list(children: itens),
        ),
      ],
    );
  }
}
