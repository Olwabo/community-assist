import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;

class UploadResult {
  final String downloadUrl;
  final String storagePath;
  const UploadResult({required this.downloadUrl, required this.storagePath});
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;


  Future<UploadResult> uploadReportPhoto({
    required String userId,
    required String reportNumber,
    File? file,
    Uint8List? bytes,
  }) async {
    final path = 'reports/$userId/$reportNumber.jpg';
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    TaskSnapshot snapshot;
    if (kIsWeb && bytes != null) {
      snapshot = await ref.putData(bytes, metadata);
    } else if (file != null) {
      snapshot = await ref.putFile(file, metadata);
    } else {
      throw Exception('No file or bytes provided for upload.');
    }

    final url = await snapshot.ref.getDownloadURL();
    return UploadResult(downloadUrl: url, storagePath: path);
  }

  Future<void> deleteByPath(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (_) {}
  }


  // Compresses and encodes a photo as Base64 for Firestore storage.
  // Returns null if the compressed image exceeds the safe Firestore size.
  Future<String?> encodePhotoAsBase64(
    File file, {
    int maxDimension = 800,
    int quality = 60,
  }) async {
    try {
      final raw = await file.readAsBytes();
      final compressed = await _compressBytes(
        raw,
        maxDimension: maxDimension,
        quality: quality,
      );

      // Firestore doc limit is 1 MB. Keep the encoded photo under 500 KB
      // to leave room for the rest of the document.
      const maxBytes = 500 * 1024;
      if (compressed.lengthInBytes > maxBytes) {
        return null;
      }

      return base64Encode(compressed);
    } catch (_) {
      return null;
    }
  }

  // Same as above but accepts raw bytes.
  Future<String?> encodeBytesAsBase64(
    Uint8List input, {
    int maxDimension = 800,
    int quality = 60,
  }) async {
    try {
      final compressed = await _compressBytes(
        input,
        maxDimension: maxDimension,
        quality: quality,
      );

      const maxBytes = 500 * 1024;
      if (compressed.lengthInBytes > maxBytes) {
        return null;
      }

      return base64Encode(compressed);
    } catch (_) {
      return null;
    }
  }

  // Decodes a Base64 string back to bytes for Image.memory().
  Uint8List? decodeBase64Photo(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

  // Internal: compress image bytes to a target size.
  Future<Uint8List> _compressBytes(
    Uint8List input, {
    int maxDimension = 800,
    int quality = 60,
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