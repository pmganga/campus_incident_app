import 'dart:math';
import 'dart:typed_data';

import 'package:campus_incident_app/utils/constants.dart';
import 'package:campus_incident_app/utils/photo_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A "camera photo": large, detailed (random pixels compress badly) and with
/// GPS location and camera details in its metadata.
Uint8List fakeCameraPhoto({int width = 2400, int height = 1600, int orientation = 1}) {
  final image = img.Image(width: width, height: height);
  final random = Random(42);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  image.exif.imageIfd['Make'] = 'TestPhone';
  image.exif.imageIfd.orientation = orientation;
  // Kigali campus coordinates: exactly what must not leak.
  image.exif.gpsIfd.gpsLatitude = -1.9441;
  image.exif.gpsIfd.gpsLongitude = 30.0619;
  return img.encodeJpg(image, quality: 95);
}

void main() {
  test('shrinks a large photo to fit the size limits', () {
    final input = fakeCameraPhoto();
    expect(input.length, greaterThan(AppConstants.photoMaxBytes));

    final output = PhotoProcessor.process(input)!;
    final decoded = img.decodeJpg(output)!;

    expect(output.length, lessThanOrEqualTo(AppConstants.photoMaxBytes));
    expect(max(decoded.width, decoded.height), lessThanOrEqualTo(AppConstants.photoMaxDimension));
    expect(decoded.width / decoded.height, closeTo(1.5, 0.01)); // shape kept
  });

  test('removes all metadata, including GPS location', () {
    final before = img.decodeJpg(fakeCameraPhoto(width: 400, height: 300))!;
    expect(before.exif.gpsIfd.gpsLatitude, isNotNull); // the input really has GPS

    final output = PhotoProcessor.process(fakeCameraPhoto(width: 400, height: 300))!;
    final after = img.decodeJpg(output)!;
    expect(after.exif.gpsIfd.isEmpty, isTrue);
    expect(after.exif.imageIfd.isEmpty, isTrue);
  });

  test('turns a sideways photo the right way up', () {
    // Orientation 6 = "rotate 90° clockwise to display".
    final output = PhotoProcessor.process(fakeCameraPhoto(width: 400, height: 200, orientation: 6))!;
    final decoded = img.decodeJpg(output)!;
    expect(decoded.width, 200);
    expect(decoded.height, 400);
  });

  test('rejects files that are not images', () {
    expect(PhotoProcessor.process(Uint8List.fromList(List.filled(100, 7))), isNull);
  });
}
