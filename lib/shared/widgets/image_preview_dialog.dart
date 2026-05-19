import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreviewDialog extends StatelessWidget {
  final String imagePath;

  const ImagePreviewDialog({super.key, required this.imagePath});

  static void show(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => ImagePreviewDialog(imagePath: path),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(child: Image.file(File(imagePath))),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}
