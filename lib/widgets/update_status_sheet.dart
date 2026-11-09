import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/incident_provider.dart';
import '../theme/status_style.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'app_text_field.dart';
import 'primary_button.dart';
import 'status_chip.dart';

/// Staff bottom sheet for moving a report to a new status, with a note that
/// the student sees in the report's "Updates" list.
class UpdateStatusSheet extends StatefulWidget {
  final Incident incident;

  const UpdateStatusSheet({super.key, required this.incident});

  static Future<void> show(BuildContext context, Incident incident) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => UpdateStatusSheet(incident: incident),
    );
  }

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<UpdateStatusSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  IncidentStatus? _selected;
  bool _showStatusError = false;
  bool _isSaving = false;
  String? _error;

  bool get _noteRequired => _selected == IncidentStatus.rejected;

  /// One-tap reasons for rejecting, including misuse.
  static const _rejectionReasons = [
    'Duplicate of an existing report',
    'Not a campus facilities issue',
    'Not enough detail to act on',
    'Spam or misuse of the reporting system',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _select(IncidentStatus status) {
    setState(() {
      _selected = status;
      _showStatusError = false;
      _error = null;
    });
  }

  Future<void> _save() async {
    final status = _selected;
    final noteValid = _formKey.currentState!.validate();
    if (status == null) {
      setState(() => _showStatusError = true);
      return;
    }
    if (!noteValid) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await context
        .read<IncidentProvider>()
        .updateStatus(widget.incident, status, note: _noteController.text);
    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _isSaving = false;
        _error = result.errorMessage;
      });
      return;
    }
    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Text(result.outcome == WriteOutcome.queuedOffline
          ? "You're offline. The update is saved and will sync automatically."
          : 'Status changed to ${status.label}. The student can see it now.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options =
        IncidentStatus.values.where((s) => s != widget.incident.status).toList();

    return Padding(
      // Keep the note field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Status',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.incident.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Current: '),
                  StatusChip(status: widget.incident.status),
                ],
              ),
              const SizedBox(height: 18),
              Text('Move to', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in options)
                    ChoiceChip(
                      avatar: Icon(status.icon, size: 18, color: status.color),
                      label: Text(status.label),
                      selected: _selected == status,
                      selectedColor: status.background,
                      showCheckmark: false,
                      side: BorderSide(
                        color: _selected == status ? status.color : Colors.grey.shade300,
                      ),
                      onSelected: _isSaving ? null : (_) => _select(status),
                    ),
                ],
              ),
              if (_showStatusError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Please choose a new status',
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _noteController,
                label: _noteRequired ? 'Reason for rejecting' : 'Note for the student (optional)',
                hintText: _noteRequired
                    ? 'e.g. Duplicate of an existing report'
                    : 'e.g. Technician assigned, expected fix by Friday',
                maxLines: 3,
                maxLength: AppConstants.statusNoteMaxLength,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => Validators.statusNote(value, required: _noteRequired),
              ),
              if (_noteRequired) ...[
                Text('Quick reasons', style: theme.textTheme.labelMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final reason in _rejectionReasons)
                      ActionChip(
                        label: Text(reason),
                        onPressed: _isSaving
                            ? null
                            : () {
                                _noteController.text = reason;
                                _formKey.currentState!.validate();
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Save Update', onPressed: _save, isLoading: _isSaving),
            ],
          ),
        ),
      ),
    );
  }
}
