import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'constants.dart';

/// Prepares a photo for upload:
/// 1. turns it the right way up (phones store rotation as metadata),
/// 2. shrinks it to at most [AppConstants.photoMaxDimension] pixels,
/// 3. removes all metadata, including the GPS location the camera may have
///    recorded (privacy), and
/// 4. re-encodes it as JPEG, lowering the quality until it fits in
///    [AppConstants.photoMaxBytes].
///
/// Returns null if the file is not an image or cannot be made small enough.
/// Pure Dart, so it can run in a background isolate with `compute()` and be
/// unit tested.
class PhotoProcessor {
  PhotoProcessor._();

  static Uint8List? process(Uint8List input) {
    final decoded = img.decodeImage(input);
    if (decoded == null) return null;

    var image = img.bakeOrientation(decoded);
    var maxSide = AppConstants.photoMaxDimension;

    // Try smaller sizes only if lowering the quality is not enough.
    while (maxSide >= 480) {
      final resized = _fit(image, maxSide);
      // A fresh, empty ExifData means no metadata is written to the JPEG.
      resized.exif = img.ExifData();
      for (final quality in const [80, 65, 50]) {
        final jpg = img.encodeJpg(resized, quality: quality);
        if (jpg.length <= AppConstants.photoMaxBytes) return jpg;
      }
      maxSide = (maxSide * 0.75).round();
      image = resized;
    }
    return null;
  }

  static img.Image _fit(img.Image image, int maxSide) {
    if (image.width <= maxSide && image.height <= maxSide) return image.clone();
    return image.width >= image.height
        ? img.copyResize(image, width: maxSide, interpolation: img.Interpolation.average)
        : img.copyResize(image, height: maxSide, interpolation: img.Interpolation.average);
  }
}
