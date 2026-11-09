import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';
import '../shared/reports_list_screen.dart';
import 'report_incident_screen.dart';

/// The student's own reports, with status chips, category filter and search.
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportsListScreen(
      title: 'My Reports',
      searchHint: 'Search by title, place or category',
      emptyState: EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No reports yet',
        message: 'When you report a campus issue, you can follow its progress here.',
        actionLabel: 'Report an issue',
        onAction: () => ReportIncidentScreen.open(context),
      ),
    );
  }
}
