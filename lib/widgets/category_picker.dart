import 'package:flutter/material.dart';

import '../models/incident.dart';
import 'category_tile.dart';

/// A grid of [CategoryTile]s that works inside a [Form], so "no category
/// selected" is reported by validate() like any other field.
class CategoryPicker extends FormField<IncidentCategory> {
  CategoryPicker({
    super.key,
    super.initialValue,
    super.validator,
    ValueChanged<IncidentCategory>? onChanged,
  }) : super(
          builder: (field) {
            final theme = Theme.of(field.context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final category in IncidentCategory.values)
                      CategoryTile(
                        category: category,
                        isSelected: field.value == category,
                        onTap: () {
                          field.didChange(category);
                          onChanged?.call(category);
                        },
                      ),
                  ],
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      field.errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            );
          },
        );
}
