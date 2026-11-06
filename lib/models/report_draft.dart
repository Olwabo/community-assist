import 'dart:typed_data';
import '../constants/app_categories.dart';
import 'report_model.dart';

class ReportDraft {
  ReportCategory? category;
  String description;
  String? photoLocalPath;
  Uint8List? photoBytes;
  String? photoUrl;
  String? photoStoragePath;
  ReportLocation? location;

  ReportDraft({
    this.category,
    this.description = '',
    this.photoLocalPath,
    this.photoBytes,
    this.photoUrl,
    this.photoStoragePath,
    this.location,
  });

  bool get hasCategory => category != null;
  bool get hasDescription => description.trim().length >= 10;
  bool get hasPhoto => photoLocalPath != null || photoBytes != null || photoUrl != null;
  bool get hasLocation => location != null;

  ReportDraft copy() {
    return ReportDraft(
      category: category,
      description: description,
      photoLocalPath: photoLocalPath,
      photoBytes: photoBytes,
      photoUrl: photoUrl,
      photoStoragePath: photoStoragePath,
      location: location,
    );
  }
}