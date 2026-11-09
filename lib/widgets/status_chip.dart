import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/status_style.dart';

/// Small coloured pill showing an incident's status, e.g. "In Progress".
class StatusChip extends StatelessWidget {
  final IncidentStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: status.color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
