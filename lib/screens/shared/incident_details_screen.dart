import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/incident_image.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/status_timeline.dart';
import '../../widgets/update_status_sheet.dart';

/// Full details of one report. Looks the report up in IncidentProvider by id,
/// so a status change made by staff appears here live.
///
/// Staff get an "Update Status" button; the student who reported it can
/// withdraw it while it is still "Submitted".
class IncidentDetailsScreen extends StatelessWidget {
  final String incidentId;

  const IncidentDetailsScreen({super.key, required this.incidentId});

  static Future<void> open(BuildContext context, String incidentId) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => IncidentDetailsScreen(incidentId: incidentId)),
      );

  @override
  Widget build(BuildContext context) {
    final incident = context.select<IncidentProvider, Incident?>(
      (provider) => provider.incidentById(incidentId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Incident Details')),
      body: incident == null
          ? const Center(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'Report not found',
                message: 'This report may have been removed.',
              ),
            )
          : _DetailsBody(incident: incident),
      bottomNavigationBar: incident == null ? null : _ActionBar(incident: incident),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  final Incident incident;

  const _DetailsBody({required this.incident});

  String _reporterText(BuildContext context) {
    if (!incident.isAnonymous) return 'Reported by ${incident.reporterName}';
    return context.read<IncidentProvider>().isStaffView
        ? 'Reported anonymously'
        : 'Reported anonymously: your name is hidden from staff';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionTitle = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Header: thumbnail, title, location, status
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IncidentImage(incident: incident, width: 72, height: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${incident.category.label} · ${incident.fullLocation}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  StatusChip(status: incident.status),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MetaRow(
          icon: Icons.calendar_today_outlined,
          text: 'Submitted on ${Formatters.dateTime(incident.createdAt)}',
        ),
        _MetaRow(
          icon: incident.isAnonymous ? Icons.visibility_off_outlined : Icons.person_outline,
          text: _reporterText(context),
        ),
        if (incident.updatedAt.isAfter(incident.createdAt))
          _MetaRow(
            icon: Icons.update,
            text: 'Last updated ${Formatters.timeAgo(incident.updatedAt)}',
          ),
        const Divider(height: 32),

        Text('Status Timeline', style: sectionTitle),
        const SizedBox(height: 14),
        StatusTimeline(incident: incident),
        const Divider(height: 32),

        Text('Description', style: sectionTitle),
        const SizedBox(height: 8),
        Text(incident.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),

        if (incident.hasPhoto) ...[
          const Divider(height: 32),
          Text('Attached Photo', style: sectionTitle),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'Open photo full screen',
            child: GestureDetector(
              onTap: () => _PhotoViewer.open(context, incident),
              child: IncidentImage(incident: incident, height: 220, width: double.infinity),
            ),
          ),
          const SizedBox(height: 4),
          Text('Tap to enlarge',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
        ],
        const Divider(height: 32),

        Text('Updates', style: sectionTitle),
        const SizedBox(height: 12),
        StatusHistoryList(history: incident.statusHistory),
      ],
    );
  }
}

/// Full-screen photo with pinch to zoom.
class _PhotoViewer extends StatelessWidget {
  final Incident incident;

  const _PhotoViewer({required this.incident});

  static Future<void> open(BuildContext context, Incident incident) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => _PhotoViewer(incident: incident)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(incident.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: FutureBuilder(
            future: context.read<IncidentProvider>().photoFor(incident),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              if (bytes == null) {
                return snapshot.connectionState == ConnectionState.done
                    ? const Text('Photo unavailable', style: TextStyle(color: Colors.white70))
                    : const CircularProgressIndicator();
              }
              return Image.memory(bytes, fit: BoxFit.contain);
            },
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final Incident incident;

  const _ActionBar({required this.incident});

  Future<void> _confirmWithdraw(BuildContext context) async {
    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw this report?'),
        content: const Text(
            'The report will be deleted and staff will no longer see it. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Leave the screen first: the report disappears from the list as soon as
    // the delete is applied locally.
    navigator.pop();
    final result = await provider.withdrawIncident(incident);
    messenger.showSnackBar(SnackBar(
      content: Text(switch (result.outcome) {
        WriteOutcome.done => 'Report withdrawn.',
        WriteOutcome.queuedOffline =>
          "You're offline. The report will be withdrawn when you reconnect.",
        WriteOutcome.failed => result.errorMessage!,
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final Widget button;
    if (provider.isStaffView) {
      button = FilledButton.icon(
        icon: const Icon(Icons.edit_note),
        label: const Text('Update Status'),
        onPressed: () => UpdateStatusSheet.show(context, incident),
      );
    } else if (provider.canWithdraw(incident)) {
      final error = Theme.of(context).colorScheme.error;
      button = OutlinedButton.icon(
        icon: const Icon(Icons.undo),
        label: const Text('Withdraw Report'),
        style: OutlinedButton.styleFrom(
          foregroundColor: error,
          side: BorderSide(color: error.withValues(alpha: 0.5)),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _confirmWithdraw(context),
      );
    } else {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: button,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
