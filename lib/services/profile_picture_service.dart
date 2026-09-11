import 'package:image_picker/image_picker.dart';

/// Open the gallery and return the local path of the picked image, or null
/// if the user cancels. Images are downscaled to keep the stored copy light.
Future<String?> pickImageFromGallery({
  double maxWidth = 1024,
  double maxHeight = 1024,
  int imageQuality = 85,
}) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: imageQuality,
  );
  return file?.path;
}