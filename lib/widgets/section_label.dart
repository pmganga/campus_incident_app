import 'package:flutter/material.dart';

/// Bold heading above a group of form fields, e.g. "Select a category".
class SectionLabel extends StatelessWidget {
  final String text;
  final String? optionalHint;

  const SectionLabel(this.text, {super.key, this.optionalHint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          text: text,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          children: [
            if (optionalHint != null)
              TextSpan(
                text: '  $optionalHint',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}
