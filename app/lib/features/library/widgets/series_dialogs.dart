import 'package:flutter/material.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

Future<bool> confirmRemoveSeries(BuildContext context) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.detailMenuRemove),
      content: Text(l.detailRemoveBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.detailRemoveConfirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 编辑书名 / 作者。取消返回 null；留空的字段返回 null（沿用原值）。
Future<({String? title, String? author})?> editSeriesDialog(
  BuildContext context,
  Series series,
) async {
  final l = context.l10n;
  final titleCtrl = TextEditingController(text: series.title);
  final authorCtrl = TextEditingController(text: series.author ?? '');

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.detailMenuEdit),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(labelText: l.detailEditTitleLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: authorCtrl,
            decoration: InputDecoration(labelText: l.detailEditAuthorLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.detailSave),
        ),
      ],
    ),
  );

  final title = titleCtrl.text.trim();
  final author = authorCtrl.text.trim();
  titleCtrl.dispose();
  authorCtrl.dispose();
  if (saved != true) return null;
  return (
    title: title.isEmpty ? null : title,
    author: author.isEmpty ? null : author,
  );
}
