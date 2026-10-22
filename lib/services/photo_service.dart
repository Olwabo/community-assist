import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Pick from gallery
  Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
    } catch (e) {
      return null;
    }
  }

  // Pick from camera
  Future<XFile?> pickFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
    } catch (e) {
      return null;
    }
  }

  // Read bytes from an XFile
  Future<Uint8List> readBytes(XFile file) async {
    return await file.readAsBytes();
  }

  // Read as File (not available on web)
  File? fileFromXFile(XFile file) {
    if (kIsWeb) return null;
    return File(file.path);
  }

  // Compress an image's bytes to keep it under a target size (KB).
  // Returns the compressed bytes.
  Future<Uint8List> compressBytes(
    Uint8List input, {
    int maxDimension = 1280,
    int quality = 75,
  }) async {
    final decoded = img.decodeImage(input);
    if (decoded == null) return input;

    img.Image resized = decoded;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      resized = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: maxDimension)
          : img.copyResize(decoded, height: maxDimension);
    }

    final encoded = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(encoded);
  }
}