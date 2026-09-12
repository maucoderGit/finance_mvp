import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Open the gallery, crop the picked image to a square, and copy the result to
/// a permanent app path. Returns null if the user cancels either step.
Future<String?> pickImageFromGallery({
  double maxWidth = 1024,
  double maxHeight = 1024,
  int imageQuality = 85,
}) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: imageQuality,
  );
  if (file == null) return null;

  CroppedFile? cropped;
  try {
    cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: imageQuality,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',
          toolbarColor: const Color(0xFF0c3c15),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Crop photo'),
      ],
    );
  } on MissingPluginException {
    // image_cropper only runs on Android/iOS/web; desktop skips cropping.
    return file.path;
  }
  if (cropped == null) return null;

  // The cropper stores its output in a cache dir that can be wiped; the app
  // reads the path from the DB later, so copy it somewhere permanent.
  // Unique name so a new picture gets a new path (Flutter caches images by path).
  final dir = await getApplicationDocumentsDirectory();
  final dest = p.join(
      dir.path, 'profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await File(cropped.path).copy(dest);
  return dest;
}