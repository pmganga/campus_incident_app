import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../shared/profile_screen.dart';
import 'home_screen.dart';
import 'my_reports_screen.dart';
import 'report_incident_screen.dart';

/// Student layout: bottom navigation (Home, Reports, Profile) with a centre
/// "+" button for reporting, as in the mockup.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  static const _homeTab = 0;
  static const _reportsTab = 1;
  static const _profileTab = 2;

  int _currentTab = _homeTab;

  void _openReports(IncidentStatus? status) {
    context.read<IncidentProvider>()
      ..clearFilters()
      ..setStatusFilter(status);
    setState(() => _currentTab = _reportsTab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab's scroll position and search text.
      body: IndexedStack(
        index: _currentTab,
        children: [
          HomeScreen(onOpenReports: _openReports),
          const MyReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        tooltip: 'Report an issue',
        onPressed: () => ReportIncidentScreen.open(context),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              isSelected: _currentTab == _homeTab,
              onTap: () => setState(() => _currentTab = _homeTab),
            ),
            _NavItem(
              icon: Icons.description_outlined,
              selectedIcon: Icons.description,
              label: 'Reports',
              isSelected: _currentTab == _reportsTab,
              onTap: () => setState(() => _currentTab = _reportsTab),
            ),
            // Space under the "+" button, labelled like the mockup.
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 34),
                child: Text(
                  'Report',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              isSelected: _currentTab == _profileTab,
              onTap: () => setState(() => _currentTab = _profileTab),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600;
    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        child: InkResponse(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? selectedIcon : icon, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
