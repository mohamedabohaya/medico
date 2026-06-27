
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class AppImageHelper {
  static bool isBase64Image(String value) {
    return value.startsWith('data:image') || value.length > 500;
  }

  static String stripDataHeader(String value) {
    if (value.contains(',')) return value.split(',').last;
    return value;
  }

  static Widget image(
    String? value, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return placeholder ?? const Icon(Icons.image_not_supported, color: Colors.grey);
    }

    try {
      if (v.startsWith('http')) {
        return Image.network(v, width: width, height: height, fit: fit);
      }

      if (isBase64Image(v)) {
        return Image.memory(
          base64Decode(stripDataHeader(v)),
          width: width,
          height: height,
          fit: fit,
        );
      }

      final f = File(v);
      if (f.existsSync()) {
        return Image.file(f, width: width, height: height, fit: fit);
      }
    } catch (_) {}

    return placeholder ?? const Icon(Icons.broken_image, color: Colors.grey);
  }

  static ImageProvider? provider(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    try {
      if (v.startsWith('http')) return NetworkImage(v);
      if (isBase64Image(v)) return MemoryImage(base64Decode(stripDataHeader(v)));
      final f = File(v);
      if (f.existsSync()) return FileImage(f);
    } catch (_) {}
    return null;
  }

  static void showPreview(BuildContext context, String? value) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: InteractiveViewer(
                child: Center(child: image(value, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
