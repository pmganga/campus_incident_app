import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../theme/status_style.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/summary_tile.dart';
import '../shared/incident_details_screen.dart';

/// Staff overview: live counts for every status and the queue of new
/// reports waiting to be picked up (oldest first).
class StaffDashboardScreen extends StatelessWidget {
  /// Switches to the All Reports tab, optionally pre-filtered by status.
  final void Function(IncidentStatus? status) onOpenReports;

  const StaffDashboardScreen({super.key, required this.onOpenReports});

  static const _queuePreviewSize = 5;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    final incidents = context.watch<IncidentProvider>();
    final theme = Theme.of(context);
    final queue = incidents.awaitingReview;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Hello, ${Formatters.firstName(user?.name ?? '')} 👋',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Review new reports and keep students updated on progress.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          SectionHeader(
            title: 'Overview · ${incidents.reports.length} total',
            onSeeAll: () => onOpenReports(null),
          ),
          const SizedBox(height: 10),
          // Two rows of two. Rows (not a fixed-ratio grid) let each tile take
          // the height its content needs, so large system fonts don't overflow.
          for (var i = 0; i < IncidentStatus.values.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (final (j, status) in IncidentStatus.values.skip(i).take(2).indexed) ...[
                  if (j > 0) const SizedBox(width: 8),
                  Expanded(
                    child: SummaryTile(
                      icon: status.icon,
                      count: incidents.countByStatus(status),
                      label: status.label,
                      color: status.color,
                      onTap: () => onOpenReports(status),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 24),

          SectionHeader(
            title: 'Awaiting Review',
            onSeeAll: () => onOpenReports(IncidentStatus.submitted),
          ),
          const SizedBox(height: 10),
          if (incidents.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (incidents.loadError != null)
            EmptyState(
              icon: Icons.cloud_off,
              title: 'Could not load reports',
              message: incidents.loadError!,
            )
          else if (queue.isEmpty)
            const EmptyState(
              icon: Icons.task_alt,
              title: 'All caught up',
              message: 'There are no new reports waiting for review.',
            )
          else ...[
            for (final incident in queue.take(_queuePreviewSize))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReportCard(
                  incident: incident,
                  showReporter: true,
                  onTap: () => IncidentDetailsScreen.open(context, incident.id),
                ),
              ),
            if (queue.length > _queuePreviewSize)
              Center(
                child: TextButton(
                  onPressed: () => onOpenReports(IncidentStatus.submitted),
                  child: Text('View all ${queue.length} new reports'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
