import '../constants/app_categories.dart';
import 'report_model.dart';


class ReportDraft {
  ReportCategory? category;
  String description;
  String? photoLocalPath;
  String? photoUrl;
  String? photoStoragePath;
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