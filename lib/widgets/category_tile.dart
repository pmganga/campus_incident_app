import 'package:flutter/material.dart';

import '../models/incident.dart';

/// A selectable square showing a category icon and name.
class CategoryTile extends StatelessWidget {
  final IncidentCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected ? colors.onPrimary : colors.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${category.label} category',
      child: Material(
        color: isSelected ? colors.primary : colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, color: foreground, size: 26),
                const SizedBox(height: 6),
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
