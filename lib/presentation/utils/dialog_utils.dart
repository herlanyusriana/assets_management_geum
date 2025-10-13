import 'package:flutter/material.dart';

Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Batal',
  String confirmLabel = 'Hapus',
  Color confirmColor = const Color(0xFFE11D48),
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: confirmColor,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      ) ??
      false;
}
