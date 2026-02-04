import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<Uint8List?> pickAndCropIconImage({
  required BuildContext context,
  required ImagePicker picker,
  required Widget Function(Uint8List bytes) buildCropView,
  double? maxWidth = 1024,
  double? maxHeight = 1024,
  int imageQuality = 80,
}) async {
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: imageQuality,
  );
  if (image == null) return null;
  final bytes = await image.readAsBytes();
  if (!context.mounted) return null;
  final Uint8List? cropped = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      builder: (_) => buildCropView(bytes),
    ),
  );
  return cropped;
}
