import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_card.dart';
import 'incident_details_screen.dart';

/// A searchable, filterable list of the reports in IncidentProvider.
/// Students see their own reports ("My Reports"); staff see every report.
class ReportsListScreen extends StatefulWidget {
  final String title;
  final String searchHint;
  final bool showReporter;

  /// Shown when there are no reports at all (as opposed to no matches).
  final EmptyState emptyState;

  const ReportsListScreen({
    super.key,
    required this.title,
    required this.searchHint,
    required this.emptyState,
    this.showReporter = false,
  });

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final _searchController = TextEditingController();
  late final IncidentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<IncidentProvider>();
    _searchController.text = _provider.searchQuery;
    // Filters can be reset from elsewhere (e.g. tapping a summary tile), so
    // keep the search box in sync with the provider.
    _provider.addListener(_syncSearchBox);
  }

  void _syncSearchBox() {
    if (_searchController.text.trim() != _provider.searchQuery) {
      _searchController.text = _provider.searchQuery;
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_syncSearchBox);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<IncidentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          _SortButton(selected: incidents.sort),
          _CategoryFilterButton(selected: incidents.categoryFilter),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: incidents.setSearchQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: incidents.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        onPressed: () => incidents.setSearchQuery(''),
                      ),
              ),
            ),
          ),
          _StatusFilterChips(incidents: incidents),
          if (incidents.categoryFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: Icon(incidents.categoryFilter!.icon, size: 18),
                  label: Text(incidents.categoryFilter!.label),
                  onDeleted: () => incidents.setCategoryFilter(null),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(child: _buildList(context, incidents)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, IncidentProvider incidents) {
    if (incidents.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (incidents.loadError != null) {
      return Center(
        child: EmptyState(
          icon: Icons.cloud_off,
          title: 'Could not load reports',
          message: incidents.loadError!,
        ),
      );
    }
    if (incidents.reports.isEmpty) {
      return Center(child: widget.emptyState);
    }

    final results = incidents.filteredIncidents;
    if (results.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No matching reports',
          message: 'Try a different search or filter.',
          actionLabel: 'Clear filters',
          onAction: incidents.clearFilters,
        ),
      );
    }

    return ListView.separated(
      // Extra bottom space so the last card can scroll clear of the + button.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => ReportCard(
        incident: results[index],
        showReporter: widget.showReporter,
        onTap: () => IncidentDetailsScreen.open(context, results[index].id),
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  final IncidentProvider incidents;

  const _StatusFilterChips({required this.incidents});

  @override
  Widget build(BuildContext context) {
    final options = <IncidentStatus?>[null, ...IncidentStatus.values];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = options[index];
          final count =
              status == null ? incidents.reports.length : incidents.countByStatus(status);
          return ChoiceChip(
            label: Text('${status?.label ?? 'All'} ($count)'),
            selected: incidents.statusFilter == status,
            onSelected: (_) => incidents.setStatusFilter(status),
          );
        },
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final ReportSort selected;

  const _SortButton({required this.selected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ReportSort>(
      tooltip: 'Sort reports',
      icon: Badge(
        isLabelVisible: selected != ReportSort.newest,
        smallSize: 8,
        child: const Icon(Icons.swap_vert),
      ),
      onSelected: context.read<IncidentProvider>().setSort,
      itemBuilder: (_) => [
        for (final sort in ReportSort.values)
          CheckedPopupMenuItem(value: sort, checked: selected == sort, child: Text(sort.label)),
      ],
    );
  }
}

class _CategoryFilterButton extends StatelessWidget {
  final IncidentCategory? selected;

  const _CategoryFilterButton({required this.selected});

  @override
  Widget build(BuildContext context) {
    final incidents = context.read<IncidentProvider>();
    return PopupMenuButton<IncidentCategory?>(
      tooltip: 'Filter by category',
      icon: Badge(
        isLabelVisible: selected != null,
        smallSize: 8,
        child: const Icon(Icons.filter_list),
      ),
      onSelected: incidents.setCategoryFilter,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: null,
          checked: selected == null,
          child: const Text('All categories'),
        ),
        for (final category in IncidentCategory.values)
          CheckedPopupMenuItem(
            value: category,
            checked: selected == category,
            child: Text(category.label),
          ),
      ],
    );
  }
}
