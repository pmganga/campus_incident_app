import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/status_style.dart';
import '../utils/formatters.dart';

/// Three-step progress bar: Submitted → In Progress → Resolved (or Rejected).
class StatusTimeline extends StatelessWidget {
  final Incident incident;

  const StatusTimeline({super.key, required this.incident});

  static const double _dotSize = 28;

  @override
  Widget build(BuildContext context) {
    final finalStep =
        incident.status == IncidentStatus.rejected ? IncidentStatus.rejected : IncidentStatus.resolved;
    final steps = [IncidentStatus.submitted, IncidentStatus.inProgress, finalStep];
    final currentIndex = steps.indexOf(incident.status);

    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      if (i > 0) {
        children.add(Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: _dotSize / 2 - 1),
            child: Container(
              height: 2,
              color: i <= currentIndex ? steps[i].color : Colors.grey.shade300,
            ),
          ),
        ));
      }
      children.add(_Step(
        status: steps[i],
        reachedAt: _latestChangeTo(steps[i]),
        isReached: i <= currentIndex,
        isCurrent: i == currentIndex,
      ));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  DateTime? _latestChangeTo(IncidentStatus status) {
    DateTime? latest;
    for (final change in incident.statusHistory) {
      if (change.status == status && (latest == null || change.at.isAfter(latest))) {
        latest = change.at;
      }
    }
    return latest;
  }
}

class _Step extends StatelessWidget {
  final IncidentStatus status;
  final DateTime? reachedAt;
  final bool isReached;
  final bool isCurrent;

  const _Step({
    required this.status,
    required this.reachedAt,
    required this.isReached,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = isReached ? status.color : Colors.grey.shade400;
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: StatusTimeline._dotSize,
            height: StatusTimeline._dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReached ? color : Colors.white,
              border: Border.all(color: color, width: 2),
              boxShadow: isCurrent
                  ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8)]
                  : null,
            ),
            child: Icon(
              isReached && !isCurrent ? Icons.check : status.icon,
              size: 15,
              color: isReached ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isReached ? Colors.black87 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reachedAt == null ? '—' : Formatters.shortDateTime(reachedAt!),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Every status change, newest first, with who made it and their note.
class StatusHistoryList extends StatelessWidget {
  final List<StatusChange> history;

  const StatusHistoryList({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final entries = [...history]..sort((a, b) => b.at.compareTo(a.at));
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final change in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: change.status.background,
                  child: Icon(change.status.icon, size: 17, color: change.status.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${change.status.label} · ${change.changedByName}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (change.note != null && change.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(change.note!, style: theme.textTheme.bodyMedium),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.dateTime(change.at),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
