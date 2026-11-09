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
import 'report_incident_screen.dart';

/// Student dashboard: greeting, report banner, live summary and recent reports.
class HomeScreen extends StatelessWidget {
  /// Switches to the My Reports tab, optionally pre-filtered by status.
  final void Function(IncidentStatus? status) onOpenReports;

  const HomeScreen({super.key, required this.onOpenReports});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    final incidents = context.watch<IncidentProvider>();
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        // Extra bottom space so nothing stays hidden behind the + button.
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hello, ${Formatters.firstName(user?.name ?? '')} 👋',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  Formatters.initials(user?.name ?? ''),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Help make our campus safer. Report issues and track their resolution.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _ReportBanner(onReport: () => ReportIncidentScreen.open(context)),
          const SizedBox(height: 24),

          SectionHeader(title: 'Report Summary', onSeeAll: () => onOpenReports(null)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  icon: Icons.description_outlined,
                  count: incidents.reports.length,
                  label: 'My Reports',
                  color: theme.colorScheme.primary,
                  onTap: () => onOpenReports(null),
                ),
              ),
              for (final status in const [
                IncidentStatus.inProgress,
                IncidentStatus.resolved,
                IncidentStatus.submitted,
              ]) ...[
                const SizedBox(width: 8),
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
          const SizedBox(height: 24),

          SectionHeader(title: 'Recent Reports', onSeeAll: () => onOpenReports(null)),
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
          else if (incidents.recentIncidents.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No reports yet',
              message: 'Issues you report will appear here so you can track them.',
              actionLabel: 'Report an issue',
              onAction: () => ReportIncidentScreen.open(context),
            )
          else
            for (final incident in incidents.recentIncidents)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReportCard(
                  incident: incident,
                  onTap: () => IncidentDetailsScreen.open(context, incident.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _ReportBanner extends StatelessWidget {
  final VoidCallback onReport;

  const _ReportBanner({required this.onReport});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [primary, Color.lerp(primary, Colors.white, 0.35)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'See an issue on campus?',
            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Report it and help improve our learning environment.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onReport,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: primary,
                      child: const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Report an Issue',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
