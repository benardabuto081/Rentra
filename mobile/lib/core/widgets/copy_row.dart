import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'feedback.dart';

/// A labelled value with a copy button that confirms what was copied.
class CopyRow extends StatelessWidget {
  const CopyRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) showSuccessSnackBar(context, '$label copied.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xxs),
                SelectableText(
                  value,
                  style: valueStyle ?? AppTypography.subheading,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy ${label.toLowerCase()}',
            icon: const Icon(Icons.copy_outlined, color: AppColors.primary),
            onPressed: () => _copy(context),
          ),
        ],
      ),
    );
  }
}
