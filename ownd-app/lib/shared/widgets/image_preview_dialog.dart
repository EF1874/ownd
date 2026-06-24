import 'package:flutter/material.dart';
import 'app_image.dart';

class ImagePreviewDialog extends StatelessWidget {
  final String imagePath;

  const ImagePreviewDialog({super.key, required this.imagePath});

  static void show(BuildContext context, String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (ctx) => ImagePreviewDialog(imagePath: path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: AppImage(path: imagePath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
