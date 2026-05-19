import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageServiceProvider = Provider((ref) => ImageService());

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Picks and optionally crops an image.
  /// For item photos, we might use a wider aspect ratio (e.g. 16:9) or free crop.
  Future<File?> pickAndCropImage({
    required BuildContext context,
    required ImageSource source,
    bool isSquare = false, // Set true for icons
  }) async {
    try {
      final colorScheme = Theme.of(context).colorScheme;
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪',
            toolbarColor: colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isSquare
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: '裁剪', aspectRatioLockEnabled: false),
        ],
      );

      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      debugPrint('Error picking/cropping image: $e');
      return null;
    }
  }

  /// Saves an image to the local AppDir/Images folder.
  /// Uses device UUID and timestamp to ensure uniqueness.
  Future<String?> saveImageToAppDirectory(
    File imageFile,
    String deviceUuid, {
    bool isIcon = false,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final extension = path.extension(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final typePrefix = isIcon ? 'icon' : 'item';
      final fileName = '${typePrefix}_${deviceUuid}_$timestamp$extension';
      final savedPath = '${imagesDir.path}/$fileName';

      final savedImage = await imageFile.copy(savedPath);
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  /// Deletes a local image file.
  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
}
