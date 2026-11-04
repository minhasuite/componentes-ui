import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion_view.dart';
import 'ss_button.dart';
import 'ss_list.dart';
import 'ss_sheet.dart';

/// Pergunta sim/não e devolve `true` só se confirmou. Botões empilhados na
/// largura toda; [danger] pinta a confirmação de vermelho.
Future<bool> showSsConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool danger = false,
  IconData? icon,
}) async =>
    await showDialog<bool>(
      context: context,
      animationStyle: SsOverlayMotion.dialog(context),
      builder: (_) => SsConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        danger: danger,
        icon: icon,
      ),
    ) ??
    false;

/// Ação irreversível (zerar dados, excluir conta): só libera a confirmação
/// depois de digitar [word] (sem diferenciar maiúscula).
Future<bool> showSsConfirmIrreversible(
  BuildContext context, {
  required String title,
  String? message,
  String word = 'APAGAR',
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
}) async =>
    await showDialog<bool>(
      context: context,
      animationStyle: SsOverlayMotion.dialog(context),
      builder: (_) => SsConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        danger: true,
        icon: Icons.warning_amber_rounded,
        word: word,
      ),
    ) ??
    false;

/// Conteúdo de [showSsConfirm] / [showSsConfirmIrreversible] (público para o
/// catálogo). Fecha devolvendo `true`/`false`.
class SsConfirmDialog extends StatefulWidget {
  const SsConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.danger = false,
    this.icon,
    this.word,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final IconData? icon;

  /// Com ela, a confirmação só libera depois de digitar a palavra.
  final String? word;

  @override
  State<SsConfirmDialog> createState() => _SsConfirmDialogState();
}

class _SsConfirmDialogState extends State<SsConfirmDialog> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  // O cartão abre de 0,9 com mola (o fundo só esmaece).
  @override
  Widget build(BuildContext context) => SsRouteScale(child: _dialogo(context));

  Widget _dialogo(BuildContext context) {
    final c = SsColors.of(context);
    final word = widget.word;
    final liberado = word == null || _texto.text.trim().toUpperCase() == word.toUpperCase();
    return AlertDialog(
      icon: widget.icon == null ? null : _Bolha(widget.icon!, danger: widget.danger),
      title: Text(widget.title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message != null)
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.ink2, height: 1.4),
            ),
          if (word != null) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _texto,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: 'Digite $word para confirmar'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
      actions: [
        _Empilhados(
          confirmLabel: widget.confirmLabel,
          cancelLabel: widget.cancelLabel,
          danger: widget.danger,
          onConfirm: liberado ? () => Navigator.pop(context, true) : null,
          onCancel: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}

/// Pede um texto curto. Devolve o texto aparado, ou `null` se cancelou ou
/// deixou vazio (com [allowEmpty], vazio volta `''`: apagar a observação).
/// [validator] devolve a mensagem de erro (ou `null` se ok). [message] é um
/// texto acima do campo; [maxLines] > 1 vira campo de várias linhas.
Future<String?> showSsPrompt(
  BuildContext context, {
  required String title,
  String label = 'Nome',
  String initial = '',
  String? hint,
  String? Function(String value)? validator,
  TextInputType keyboardType = TextInputType.text,
  String confirmLabel = 'Salvar',
  bool allowEmpty = false,
  int maxLines = 1,
  int? maxLength,
  String? message,
}) async {
  final r = await showDialog<String>(
    context: context,
    animationStyle: SsOverlayMotion.dialog(context),
    builder: (_) => SsPromptDialog(
      title: title,
      label: label,
      initial: initial,
      hint: hint,
      validator: validator,
      keyboardType: keyboardType,
      confirmLabel: confirmLabel,
      maxLines: maxLines,
      maxLength: maxLength,
      message: message,
    ),
  );
  return (r == null || (r.isEmpty && !allowEmpty)) ? null : r;
}

/// Conteúdo de [showSsPrompt] (público para o catálogo).
class SsPromptDialog extends StatefulWidget {
  const SsPromptDialog({
    super.key,
    required this.title,
    this.label = 'Nome',
    this.initial = '',
    this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.confirmLabel = 'Salvar',
    this.maxLines = 1,
    this.maxLength,
    this.message,
  });

  final String title;
  final String label;
  final String initial;
  final String? hint;
  final String? Function(String value)? validator;
  final TextInputType keyboardType;
  final String confirmLabel;
  final int maxLines;
  final int? maxLength;
  final String? message;

  @override
  State<SsPromptDialog> createState() => _SsPromptDialogState();
}

class _SsPromptDialogState extends State<SsPromptDialog> {
  late final _texto = TextEditingController(text: widget.initial);
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_form.currentState!.validate()) Navigator.pop(context, _texto.text.trim());
  }

  @override
  Widget build(BuildContext context) => SsRouteScale(child: _dialogo(context));

  Widget _dialogo(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: TextStyle(color: SsColors.of(context).ink2, fontSize: AppType.sub),
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _texto,
            autofocus: true,
            keyboardType: widget.maxLines > 1 ? TextInputType.multiline : widget.keyboardType,
            textCapitalization: TextCapitalization.sentences,
            maxLines: widget.maxLines,
            minLines: 1,
            maxLength: widget.maxLength,
            decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
            validator: widget.validator == null ? null : (v) => widget.validator!((v ?? '').trim()),
            onFieldSubmitted: widget.maxLines > 1 ? null : (_) => _salvar(),
          ),
        ],
      ),
    ),
    actions: [
      _Empilhados(
        confirmLabel: widget.confirmLabel,
        cancelLabel: 'Cancelar',
        onConfirm: _salvar,
        onCancel: () => Navigator.pop(context),
      ),
    ],
  );
}

/// Bloqueia a tela (fundo escurecido, spinner e [label]) enquanto [task]
/// roda, e sempre fecha no fim. Devolve o resultado ou repassa o erro:
/// `final r = await ssRunBlocking(context, () => api.salvar(p));`
/// Com [onCancel], o cartão ganha "Cancelar": chama [onCancel] (o app cancela
/// o `CancelToken`, e a [task] termina com erro) e a tela fecha quando ela acabar.
Future<T> ssRunBlocking<T>(
  BuildContext context,
  Future<T> Function() task, {
  String label = 'Um instante…',
  VoidCallback? onCancel,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final rota = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: SsBlockingIndicator(label: label, onCancel: onCancel),
    ),
  );
  navigator.push(rota);
  try {
    return await task();
  } finally {
    if (rota.isCurrent) {
      navigator.pop();
    } else if (rota.isActive) {
      navigator.removeRoute(rota);
    }
  }
}

/// O cartão de espera do [ssRunBlocking] (público para o catálogo).
class SsBlockingIndicator extends StatefulWidget {
  const SsBlockingIndicator({super.key, this.label = 'Um instante…', this.onCancel});

  final String label;
  final VoidCallback? onCancel;

  @override
  State<SsBlockingIndicator> createState() => _SsBlockingIndicatorState();
}

class _SsBlockingIndicatorState extends State<SsBlockingIndicator> {
  var _cancelado = false;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Center(
      child: Semantics(
        liveRegion: true,
        label: _cancelado ? 'Cancelando…' : widget.label,
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: c.accent)),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Text(
                        _cancelado ? 'Cancelando…' : widget.label,
                        style: TextStyle(color: c.ink, fontWeight: FontWeight.w700, fontSize: AppType.body),
                      ),
                    ),
                  ],
                ),
                if (widget.onCancel != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _cancelado
                        ? null
                        : () {
                            setState(() => _cancelado = true);
                            widget.onCancel!();
                          },
                    child: const Text('Cancelar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Em volta de um formulário: com [dirty], voltar pergunta "Descartar as
/// alterações?" antes de sair. [isDirty] é a alternativa sem rebuild: é
/// chamada na hora de voltar (ex.: `() => _form.mudou`).
class SsUnsavedGuard extends StatelessWidget {
  const SsUnsavedGuard({super.key, this.dirty = false, this.isDirty, required this.child});

  final bool dirty;
  final bool Function()? isDirty;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && isDirty == null,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final navigator = Navigator.of(context);
      if (!dirty && !(isDirty?.call() ?? false)) return navigator.pop();
      final ok = await showSsConfirm(
        context,
        title: 'Descartar as alterações?',
        message: 'O que você mudou aqui ainda não foi salvo.',
        confirmLabel: 'Descartar',
        cancelLabel: 'Continuar editando',
        danger: true,
      );
      if (ok) navigator.pop();
    },
    child: child,
  );
}

/// De onde vem a foto. O app chama o `image_picker` (ou apaga, em [remove]).
enum SsImageSource { camera, gallery, remove }

/// Folha "Câmera / Galeria (/ Remover)". Devolve `null` se fechou sem
/// escolher.
Future<SsImageSource?> showSsImageSource(BuildContext context, {bool allowRemove = false, String title = 'Foto'}) =>
    showSsSheet<SsImageSource>(
      context,
      title: title,
      child: SsImageSourcePicker(allowRemove: allowRemove),
    );

/// Opções de [showSsImageSource] (público para o catálogo). Tocar fecha a
/// folha devolvendo a escolha.
class SsImageSourcePicker extends StatelessWidget {
  const SsImageSourcePicker({super.key, this.allowRemove = false});

  final bool allowRemove;

  @override
  Widget build(BuildContext context) {
    void escolher(SsImageSource s) => Navigator.pop(context, s);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SsListItem(
          icon: Icons.photo_camera_outlined,
          title: 'Tirar foto',
          subtitle: 'Abre a câmera',
          onTap: () => escolher(SsImageSource.camera),
        ),
        SsListItem(
          icon: Icons.photo_library_outlined,
          title: 'Escolher da galeria',
          onTap: () => escolher(SsImageSource.gallery),
        ),
        if (allowRemove)
          SsListItem(
            icon: Icons.delete_outline,
            title: 'Remover foto',
            tone: AppColors.danger,
            onTap: () => escolher(SsImageSource.remove),
          ),
      ],
    );
  }
}

class _Empilhados extends StatelessWidget {
  const _Empilhados({
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.danger = false,
  });

  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback onCancel;
  final bool danger;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SsButton(
        label: confirmLabel,
        variant: danger ? SsButtonVariant.danger : SsButtonVariant.primary,
        onPressed: onConfirm,
      ),
      const SizedBox(height: 8),
      SsButton(label: cancelLabel, variant: SsButtonVariant.ghost, onPressed: onCancel),
    ],
  );
}

/// Ícone no topo do diálogo, numa bolha da cor do assunto.
class _Bolha extends StatelessWidget {
  const _Bolha(this.icon, {this.danger = false});
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: danger ? AppColors.danger.withValues(alpha: c.isDark ? .2 : .12) : c.accentSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: danger ? c.dangerText : c.accentText, size: 26),
    );
  }
}
