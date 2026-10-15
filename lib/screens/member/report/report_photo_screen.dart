import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/report_draft.dart';
import '../../../services/photo_service.dart';
import '../../../utils/snackbar.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/step_progress.dart';
import 'package:image_picker/image_picker.dart';
import 'report_location_screen.dart';

class ReportPhotoScreen extends StatefulWidget {
  final ReportDraft draft;

  const ReportPhotoScreen({super.key, required this.draft});

  @override
  State<ReportPhotoScreen> createState() => _ReportPhotoScreenState();
}

class _ReportPhotoScreenState extends State<ReportPhotoScreen> {
  final _photoService = PhotoService();

  Uint8List? _previewBytes;
  String? _localPath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Restore previous photo if user came back
    final existing = widget.draft.photoLocalPath;
    if (existing != null && !kIsWeb) {
      _loadExisting(File(existing));
    }
  }

  Future<void> _loadExisting(File file) async {
    try {
      final bytes = await file.readAsBytes();
      setState(() {
        _previewBytes = bytes;
        _localPath = file.path;
      });
    } catch (_) {}
  }

  Future<void> _pickFromCamera() async {
    setState(() => _isProcessing = true);

    final file = await _photoService.pickFromCamera();
    if (file == null) {
      setState(() => _isProcessing = false);
      return;
    }

    await _handlePickedFile(file);
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isProcessing = true);

    final file = await _photoService.pickFromGallery();
    if (file == null) {
      setState(() => _isProcessing = false);
      return;
    }

    await _handlePickedFile(file);
  }

  Future<void> _handlePickedFile(XFile file) async {
    try {
      final rawBytes = await _photoService.readBytes(file);
      final compressed = await _photoService.compressBytes(rawBytes);

      if (!mounted) return;

      setState(() {
        _previewBytes = compressed;
        _localPath = kIsWeb ? null : file.path;
        _isProcessing = false;
      });

      AppSnackbar.success(
        context,
        'Photo ready (${(compressed.lengthInBytes / 1024).round()} KB)',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      AppSnackbar.error(context, 'Could not process photo');
    }
  }

  void _removePhoto() {
    setState(() {
      _previewBytes = null;
      _localPath = null;
    });
  }

  void _continue() {
    if (_previewBytes == null) {
      AppSnackbar.error(context, 'Please add a photo');
      return;
    }

    widget.draft.photoLocalPath = _localPath;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportLocationScreen(draft: widget.draft),
      ),
    );
  }
  void _skip() {
    widget.draft.photoLocalPath = null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportLocationScreen(draft: widget.draft),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
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
                    const StepProgress(currentStep: 2, totalSteps: 4),
                    const SizedBox(height: 24),

                    const Text(
                      'Add a Photo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'A picture helps us understand the issue faster.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildPreview(),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _photoButton(
                            icon: Icons.photo_camera_outlined,
                            label: 'Camera',
                            onTap: _isProcessing ? null : _pickFromCamera,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _photoButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: _isProcessing ? null : _pickFromGallery,
                          ),
                        ),
                      ],
                    ),
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
                    label: 'Continue',
                    icon: Icons.arrow_forward,
                    onPressed: _continue,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1.5,
        ),
      ),
      child: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : _previewBytes != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _previewBytes!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _removePhoto,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 60,
                      color: AppColors.textHint.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No photo yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Take or pick one below',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _photoButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}