import '../constants/app_categories.dart';
import 'report_model.dart';

/// A draft of a report being built across the multi-step submission flow.
/// Not yet persisted to Firestore.
class ReportDraft {
  ReportCategory? category;
  String description;
  String? photoLocalPath;    // Local file path (mobile)
  String? photoUrl;          // Remote URL (after upload, filled at submit)
  String? photoStoragePath;  // For deletion if needed
  ReportLocation? location;

  ReportDraft({
    this.category,
    this.description = '',
    this.photoLocalPath,
    this.photoUrl,
    this.photoStoragePath,
    this.location,
  });

  bool get hasCategory => category != null;
  bool get hasDescription => description.trim().length >= 10;
  bool get hasPhoto => photoLocalPath != null || photoUrl != null;
  bool get hasLocation => location != null;

  ReportDraft copy() {
    return ReportDraft(
      category: category,
      description: description,
      photoLocalPath: photoLocalPath,
      photoUrl: photoUrl,
      photoStoragePath: photoStoragePath,
      location: location,
    );
  }
}