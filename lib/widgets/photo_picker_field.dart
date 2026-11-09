
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/photo_processor.dart';

/// Optional photo for a report: take one with the camera or choose one from
/// the gallery, see a preview, and remove it again.
///
/// The photo is shrunk and its metadata (including GPS location) removed
/// before it is handed to [onChanged].
class PhotoPickerField extends StatefulWidget {
  final Uint8List? photo;
  final ValueChanged<Uint8List?> onChanged;
  final bool enabled;

  /// Replaces the device camera/gallery in tests.
  final Future<Uint8List?> Function(ImageSource source)? pickImage;

  const PhotoPickerField({
    super.key,
    required this.photo,
    required this.onChanged,
    this.enabled = true,
    this.pickImage,
  });

  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  bool _isProcessing = false;
  String? _error;

  static Future<Uint8List?> _pickFromDevice(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      // A first, cheap shrink by the platform; PhotoProcessor does the rest.
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 92,
      requestFullMetadata: false,
    );
    return file?.readAsBytes();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    try {
      final raw = await (widget.pickImage ?? _pickFromDevice)(source);
      if (raw == null || !mounted) return; // the user cancelled
      setState(() => _isProcessing = true);
      // Decoding and re-encoding takes a moment; do it off the UI thread.
      final processed = await compute(PhotoProcessor.process, raw);
      if (!mounted) return;
      if (processed == null) {
        setState(() => _error = 'This photo could not be used. Please try another one.');
      } else {
        widget.onChanged(processed);
      }
    } on PlatformException {
      if (mounted) {
        setState(() => _error = source == ImageSource.camera
            ? 'Camera access was denied. You can allow it in your phone settings.'
            : 'Photo access was denied. You can allow it in your phone settings.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = widget.photo;

    Widget content;
    if (_isProcessing) {
      content = Container(
        height: 120,
        decoration: _boxDecoration(),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Preparing photo…'),
          ],
        ),
      );
    } else if (photo != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(photo, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  tooltip: 'Remove photo',
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.enabled ? () => widget.onChanged(null) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Photo ready · ${(photo.length / 1024).round()} KB · location data removed',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      );
    } else {
      content = Row(
        children: [
          Expanded(
            child: _SourceButton(
              icon: Icons.photo_camera_outlined,
              label: 'Take photo',
              onPressed: widget.enabled ? () => _pick(ImageSource.camera) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SourceButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onPressed: widget.enabled ? () => _pick(ImageSource.gallery) : null,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        content,
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          ),
        if (photo == null && !_isProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "Show the problem, not people. Please avoid photographing other people's faces.",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      );
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SourceButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: onPressed,
    );
  }
}
