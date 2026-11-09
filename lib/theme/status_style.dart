import 'package:flutter/material.dart';

import '../models/incident.dart';

/// Colours and icons for each status, kept out of the model so the data
/// layer stays free of UI decisions.
extension IncidentStatusStyle on IncidentStatus {
  Color get color => switch (this) {
        IncidentStatus.submitted => const Color(0xFFD98A00),
        IncidentStatus.inProgress => const Color(0xFF6C4CF1),
        IncidentStatus.resolved => const Color(0xFF2E9E5B),
        IncidentStatus.rejected => const Color(0xFFD64545),
      };

  Color get background => color.withValues(alpha: 0.12);

  IconData get icon => switch (this) {
        IncidentStatus.submitted => Icons.outbox_outlined,
        IncidentStatus.inProgress => Icons.schedule,
        IncidentStatus.resolved => Icons.check_circle_outline,
        IncidentStatus.rejected => Icons.cancel_outlined,
      };
}
