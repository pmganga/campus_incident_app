import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/incident_provider.dart';

/// The incident's photo, or its category icon when there is no photo
/// (or the photo cannot be loaded).
///
/// Photos are downloaded from Firestore through IncidentProvider, which
/// caches them, so each photo is fetched only once per session.
class IncidentImage extends StatefulWidget {
  final Incident incident;
  final double? width;
  final double? height;
  final double borderRadius;

  const IncidentImage({
    super.key,
    required this.incident,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  @override
  State<IncidentImage> createState() => _IncidentImageState();
}

class _IncidentImageState extends State<IncidentImage> {
  late Future<Uint8List?> _photo;

  @override
  void initState() {
    super.initState();
    _photo = _load();
  }

  @override
  void didUpdateWidget(IncidentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incident.id != widget.incident.id ||
        oldWidget.incident.hasPhoto != widget.incident.hasPhoto) {
      _photo = _load();
    }
  }

  Future<Uint8List?> _load() => context.read<IncidentProvider>().photoFor(widget.incident);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: !widget.incident.hasPhoto
            ? _fallback(context)
            : FutureBuilder<Uint8List?>(
                future: _photo,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Container(
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final bytes = snapshot.data;
                  if (bytes == null) return _fallback(context);
                  return Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    // Decode thumbnails at their display size to save memory.
                    cacheWidth: _cacheWidth(context),
                    gaplessPlayback: true,
                    errorBuilder: (context, _, _) => _fallback(context),
                  );
                },
              ),
      ),
    );
  }

  int? _cacheWidth(BuildContext context) {
    final width = widget.width;
    if (width == null || !width.isFinite) return null;
    return (width * MediaQuery.devicePixelRatioOf(context)).round();
  }

  Widget _fallback(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconSize = (widget.height ?? 64) * 0.4;
    return Container(
      color: colors.primaryContainer.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Icon(widget.incident.category.icon,
          color: colors.primary, size: iconSize.clamp(20, 56)),
    );
  }
}
