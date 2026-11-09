import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../utils/formatters.dart';
import 'incident_image.dart';
import 'status_chip.dart';

/// One row in a list of reports: thumbnail, title, location, age and status.
class ReportCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onTap;

  /// Staff lists show who reported the issue.
  final bool showReporter;

  const ReportCard({
    super.key,
    required this.incident,
    required this.onTap,
    this.showReporter = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IncidentImage(incident: incident, width: 64, height: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      incident.fullLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            showReporter
                                ? '${Formatters.timeAgo(incident.createdAt)} · ${incident.reporterName}'
                                : Formatters.timeAgo(incident.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: incident.status),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
