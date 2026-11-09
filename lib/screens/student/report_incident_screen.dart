import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/photo_picker_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';
import '../shared/incident_details_screen.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReportIncidentScreen()),
      );

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Fields are only checked on submit at first; after a failed submit they are
  // re-checked as the user types, so fixed errors disappear straight away.
  var _autovalidateMode = AutovalidateMode.disabled;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationDetailController = TextEditingController();

  IncidentCategory? _category;
  String? _location;
  Uint8List? _photo;
  bool _isAnonymous = false;
  bool _hasUnsavedChanges = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationDetailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      _showMessage('Please fix the highlighted fields.');
      return;
    }
    FocusScope.of(context).unfocus();
    final provider = context.read<IncidentProvider>();

    // Misuse/duplicate check: the same student reporting the same kind of
    // problem in the same place while their earlier report is still open.
    final similar = provider.findSimilarOpenReport(_category!, _location!);
    if (similar != null && !await _confirmDuplicate(similar)) return;
    if (!mounted) return;

    final result = await provider.submitIncident(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category!,
      location: _location!,
      locationDetail: _locationDetailController.text,
      photo: _photo,
      isAnonymous: _isAnonymous,
    );
    if (!mounted) return;

    switch (result.outcome) {
      case WriteOutcome.done:
        _showMessage('Report submitted. You can track its status in My Reports.');
        _closeScreen();
      case WriteOutcome.queuedOffline:
        _showMessage(
            'Your report is saved on this phone and will be sent automatically when you are back online.');
        _closeScreen();
      case WriteOutcome.failed:
        _showMessage(result.errorMessage!);
    }
  }

  /// Returns true if the student wants to submit anyway.
  Future<bool> _confirmDuplicate(Incident similar) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Already reported?'),
        content: Text(
          'You already have an open ${similar.category.label.toLowerCase()} report at '
          '${similar.location}:\n\n"${similar.title}" (${similar.status.label})\n\n'
          'If it is the same problem, there is no need to report it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'view'),
            child: const Text('View existing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'submit'),
            child: const Text('Submit anyway'),
          ),
        ],
      ),
    );
    if (choice == 'view' && mounted) {
      IncidentDetailsScreen.open(context, similar.id);
    }
    return choice == 'submit';
  }

  void _setPhoto(Uint8List? photo) {
    setState(() {
      _photo = photo;
      _hasUnsavedChanges = true;
    });
  }

  void _closeScreen() {
    setState(() => _hasUnsavedChanges = false);
    // Wait one frame so PopScope sees that there are no unsaved changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this report?'),
        content: const Text('The details you entered will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) _closeScreen();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<IncidentProvider>();
    final isSubmitting = incidents.isSubmitting;
    final mutedStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600);

    return PopScope(
      canPop: !_hasUnsavedChanges && !isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isSubmitting) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Report an Incident')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            onChanged: () {
              if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (incidents.nextReportAllowedAt case final allowedAt?)
                  _DailyLimitBanner(allowedAt: allowedAt),
                const SectionLabel('Select a category'),
                CategoryPicker(
                  initialValue: _category,
                  validator: (value) =>
                      Validators.requiredSelection(value, 'Please choose a category'),
                  onChanged: (value) => _category = value,
                ),
                const SizedBox(height: 24),

                const SectionLabel('Title'),
                AppTextField(
                  controller: _titleController,
                  label: 'Title',
                  hintText: 'Briefly describe the issue…',
                  maxLength: AppConstants.titleMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.incidentTitle,
                ),
                const SizedBox(height: 12),

                const SectionLabel('Description'),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hintText: 'What happened, since when, and who is affected?',
                  maxLines: 6,
                  maxLength: AppConstants.descriptionMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.incidentDescription,
                ),
                const SizedBox(height: 12),

                const SectionLabel('Location'),
                DropdownButtonFormField<String>(
                  initialValue: _location,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Campus area',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: [
                    for (final place in AppConstants.campusLocations)
                      DropdownMenuItem(value: place, child: Text(place)),
                  ],
                  validator: (value) =>
                      Validators.requiredSelection(value, 'Please choose a location'),
                  onChanged: (value) => _location = value,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _locationDetailController,
                  label: 'Room or exact spot (optional)',
                  hintText: 'e.g. Room 204, 2nd floor washroom',
                  icon: Icons.meeting_room_outlined,
                  maxLength: AppConstants.locationDetailMaxLength,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),

                const SectionLabel('Photo', optionalHint: '(optional)'),
                PhotoPickerField(
                  photo: _photo,
                  enabled: !isSubmitting,
                  onChanged: _setPhoto,
                ),
                const SizedBox(height: 16),

                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    value: _isAnonymous,
                    onChanged: isSubmitting
                        ? null
                        : (value) => setState(() {
                              _isAnonymous = value;
                              _hasUnsavedChanges = true;
                            }),
                    secondary: const Icon(Icons.visibility_off_outlined),
                    title: const Text('Report anonymously'),
                    subtitle: const Text('Staff will see "Anonymous student" instead of your name.'),
                  ),
                ),
                const SizedBox(height: 24),

                PrimaryButton(
                  label: 'Submit Report',
                  onPressed: incidents.hasReachedDailyLimit ? null : _submit,
                  isLoading: isSubmitting,
                ),
                const SizedBox(height: 12),
                Text(
                  _isAnonymous
                      ? 'Your name will be hidden from staff. You can still track the report here.'
                      : 'Your name is shared with campus staff so they can follow up.',
                  textAlign: TextAlign.center,
                  style: mutedStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyLimitBanner extends StatelessWidget {
  final DateTime allowedAt;

  const _DailyLimitBanner({required this.allowedAt});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You have submitted ${AppConstants.dailyReportLimit} reports in the last 24 hours. '
              'To prevent spam, you can submit again from '
              '${Formatters.shortDateTime(allowedAt)}.',
            ),
          ),
        ],
      ),
    );
  }
}
