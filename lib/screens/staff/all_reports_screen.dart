import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';
import '../shared/reports_list_screen.dart';

/// Every report on campus, for staff, with the same filters as My Reports
/// plus search by reporter name.
class AllReportsScreen extends StatelessWidget {
  const AllReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportsListScreen(
      title: 'All Reports',
      searchHint: 'Search by title, place, category or student',
      showReporter: true,
      emptyState: EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No reports yet',
        message: 'Reports submitted by students will appear here.',
      ),
    );
  }
}
