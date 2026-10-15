import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../constants/app_categories.dart';
import '../../../constants/app_colors.dart';
import '../../../models/report_draft.dart';
import '../../../services/auth_service.dart';
import '../../../services/report_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/snackbar.dart';
import '../../../widgets/location_map.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/step_progress.dart';
import 'report_confirmation_screen.dart';


class ReportReviewScreen extends StatefulWidget {
  final ReportDraft draft;

  const ReportReviewScreen({super.key, required this.draft});

  @override
  State<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends State<ReportReviewScreen> {
  final _auth = AuthService();
  final _reportService = ReportService();
  final _storageService = StorageService();

  bool _isSubmitting = false;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _loadPhotoPreview();
  }

  Future<void> _loadPhotoPreview() async {
    final path = widget.draft.photoLocalPath;
    if (path == null || kIsWeb) return;
    try {
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      setState(() => _photoBytes = bytes);
    } catch (_) {}
  }

  Future<void> _submit() async {
    final draft = widget.draft;

    if (draft.category == null ||
        draft.description.isEmpty ||
        draft.location == null) {
      AppSnackbar.error(context, 'Incomplete report. Please go back.');
      return;
    }

    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      AppSnackbar.error(context, 'You must be logged in');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final profile = await _auth.getCurrentUserModel();
      if (profile == null) {
        throw Exception('User profile not found');
      }

      // Encode photo as Base64 (if provided)
      String? photoBase64;

      if (draft.photoLocalPath != null && !kIsWeb) {
        photoBase64 = await _storageService.encodePhotoAsBase64(
          File(draft.photoLocalPath!),
          maxDimension: 800,
          quality: 60,
        );

        if (photoBase64 == null) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          AppSnackbar.error(
            context,
            'Photo is too large. Please retake or choose a smaller image.',
          );
          return;
        }
      }

      // Create the report
      final created = await _reportService.submitReport(
        userId: profile.uid,
        userName: profile.fullName,
        userEmail: profile.email,
        category: draft.category!,
        description: draft.description,
        location: draft.location!,
        photoBase64: photoBase64,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReportConfirmationScreen(report: created),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Submission failed: $e');
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepProgress(currentStep: 4, totalSteps: 4),
                    const SizedBox(height: 24),

                    const Text(
                      'Review your report',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Check everything before submitting.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _section(
                      'Category',
                      Row(
                        children: [
                          Icon(
                            draft.category?.icon ?? Icons.help_outline,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            draft.category?.label ?? 'Not selected',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _section(
                      'Description',
                      Text(
                        draft.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    if (draft.photoLocalPath != null ||
                        draft.photoUrl != null) ...[
                      _section(
                        'Photo',
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _photoBytes != null
                              ? Image.memory(
                                  _photoBytes!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: AppColors.divider,
                                  child: const Center(
                                    child: Text('Photo attached'),
                                  ),
                                ),
                        ),
                      ),
                    ],

                    if (draft.location != null) ...[
                      _section(
                        'Location',
                        LocationMap(
                          location: draft.location!,
                          height: 200,
                          interactive: false,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Submit Report',
                    icon: Icons.send,
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'By submitting, you confirm this information is accurate.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}