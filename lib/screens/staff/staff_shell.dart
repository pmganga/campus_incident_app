import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../shared/profile_screen.dart';
import 'all_reports_screen.dart';
import 'staff_dashboard_screen.dart';

/// Staff layout: Dashboard, All Reports and Profile tabs.
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  static const _reportsTab = 1;

  int _currentTab = 0;

  void _openReports(IncidentStatus? status) {
    context.read<IncidentProvider>()
      ..clearFilters()
      ..setStatusFilter(status);
    setState(() => _currentTab = _reportsTab);
  }

  @override
  Widget build(BuildContext context) {
    final newCount = context.select<IncidentProvider, int>(
      (p) => p.countByStatus(IncidentStatus.submitted),
    );

    return Scaffold(
      // IndexedStack keeps each tab's scroll position and search text.
      body: IndexedStack(
        index: _currentTab,
        children: [
          StaffDashboardScreen(onOpenReports: _openReports),
          const AllReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: newCount > 0,
              label: Text('$newCount'),
              child: const Icon(Icons.list_alt_outlined),
            ),
            selectedIcon: const Icon(Icons.list_alt),
            label: 'All Reports',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
