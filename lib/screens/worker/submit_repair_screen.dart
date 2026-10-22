import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/photo_service.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';
import '../../utils/snackbar.dart';
import '../../widgets/primary_button.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_categories.dart';
import '../../models/notification_model.dart';

class SubmitRepairScreen extends StatefulWidget {
  final ReportModel report;

  const SubmitRepairScreen({super.key, required this.report});

  @override
  State<SubmitRepairScreen> createState() => _SubmitRepairScreenState();
}

class _SubmitRepairScreenState extends State<SubmitRepairScreen> {
  final _auth = AuthService();
  final _reportService = ReportService();
  final _photoService = PhotoService();
  final _storageService = StorageService();
  final _locationService = LocationService();
  final _notificationService = NotificationService();

  final _notesCtrl = TextEditingController();

  Uint8List? _photoBytes;
  String? _photoLocalPath;
  ReportLocation? _repairLocation;
  String? _distanceText;

  bool _pickingPhoto = false;
  bool _gettingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _pickingPhoto = true);

    final file = source == ImageSource.camera
        ? await _photoService.pickFromCamera()
        : await _photoService.pickFromGallery();

    if (file == null) {
      setState(() => _pickingPhoto = false);
      return;
    }

    try {
      final raw = await _photoService.readBytes(file);
      final compressed = await _photoService.compressBytes(raw);

      if (!mounted) return;
      setState(() {
        _photoBytes = compressed;
        _photoLocalPath = kIsWeb ? null : file.path;
        _pickingPhoto = false;
      });

      AppSnackbar.success(
        context,
        'Photo ready (${(compressed.lengthInBytes / 1024).round()} KB)',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pickingPhoto = false);
      AppSnackbar.error(context, 'Could not process photo');
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _gettingLocation = true);

    final result = await _locationService.getCurrentLocation();

    if (!mounted) return;

    if (result.isSuccess) {
      final loc = result.location!;
      final distance = Geolocator.distanceBetween(
        widget.report.location.latitude,
        widget.report.location.longitude,
        loc.latitude,
        loc.longitude,
      );

      setState(() {
        _repairLocation = loc;
        _distanceText = distance < 1000
            ? '${distance.toStringAsFixed(0)} m'
            : '${(distance / 1000).toStringAsFixed(1)} km';
        _gettingLocation = false;
      });

      AppSnackbar.success(context, 'Location captured');
    } else {
      setState(() => _gettingLocation = false);
      AppSnackbar.error(context, result.error ?? 'Could not get location');
    }
  }

  Future<void> _submit() async {
    // Validation
    if (_photoBytes == null) {
      AppSnackbar.error(context, 'Please add an after-repair photo');
      return;
    }
    if (_repairLocation == null) {
      AppSnackbar.error(context, 'Please capture your location');
      return;
    }
    if (_notesCtrl.text.trim().length < 10) {
      AppSnackbar.error(context, 'Repair notes must be at least 10 characters');
      return;
    }

    final workerUid = _auth.currentUid;
    if (workerUid == null) {
      AppSnackbar.error(context, 'Not authenticated');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Encode photo
      String? base64Photo;
      if (_photoLocalPath != null) {
        base64Photo = await _storageService.encodePhotoAsBase64(
          File(_photoLocalPath!),
        );
      } else if (_photoBytes != null) {
        base64Photo = await _storageService.encodeBytesAsBase64(_photoBytes!);
      }

      if (base64Photo == null) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        AppSnackbar.error(context, 'Photo too large. Use a smaller one.');
        return;
      }

      // Submit to Firestore
      await _reportService.submitRepairEvidence(
        reportId: widget.report.id,
        workerUid: workerUid,
        repairLocation: _repairLocation!,
        repairNotes: _notesCtrl.text.trim(),
        repairPhotoBase64: base64Photo,
      );

      // Notify reporter
      await _notificationService.createNotification(
        userId: widget.report.userId,
        title: 'Repair Completed',
        body: 'Report ${widget.report.reportNumber} has been repaired. '
            'Please verify.',
        type: NotificationType.statusChange,
        reportId: widget.report.id,
        reportNumber: widget.report.reportNumber,
        data: {'newStatus': 'repaired'},
      );

      if (!mounted) return;
      AppSnackbar.success(context, 'Repair evidence submitted');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackbar.error(context, 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Repair Evidence'),
        backgroundColor: const Color(0xFF14B8A6),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report reference banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF14B8A6),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.report.reportNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF14B8A6),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.report.category.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Photo section
                    const Text(
                      'After-Repair Photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Take a photo of the completed repair.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildPhotoPreview(),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _photoButton(
                            icon: Icons.photo_camera_outlined,
                            label: 'Camera',
                            onTap: _pickingPhoto
                                ? null
                                : () => _pickPhoto(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _photoButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: _pickingPhoto
                                ? null
                                : () => _pickPhoto(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Location section
                    const Text(
                      'Location Confirmation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Capture your current location to prove the repair was done on site.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildLocationCard(),

                    const SizedBox(height: 28),

                    // Notes section
                    const Text(
                      'Repair Notes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Describe what was done to fix the issue.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. Replaced the broken streetlight bulb and cleaned the housing.',
                      ),
                    ),

                    const SizedBox(height: 20),
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
              child: PrimaryButton(
                label: 'Submit for Verification',
                icon: Icons.check_circle_outline,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: _pickingPhoto
          ? const Center(child: CircularProgressIndicator())
          : _photoBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.memory(
                        _photoBytes!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() {
                              _photoBytes = null;
                              _photoLocalPath = null;
                            }),
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
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 44,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No photo yet',
                      style: TextStyle(color: AppColors.textHint),
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF14B8A6), size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
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

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _repairLocation != null
              ? AppColors.success
              : AppColors.divider,
          width: _repairLocation != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _repairLocation != null
                    ? Icons.check_circle
                    : Icons.location_searching,
                color: _repairLocation != null
                    ? AppColors.success
                    : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _repairLocation != null
                      ? 'Location captured'
                      : 'No location captured',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _repairLocation != null
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (_repairLocation != null) ...[
            const SizedBox(height: 12),
            _infoRow(
              'Original',
              '${widget.report.location.latitude.toStringAsFixed(5)}, '
                  '${widget.report.location.longitude.toStringAsFixed(5)}',
            ),
            const SizedBox(height: 4),
            _infoRow(
              'Yours',
              '${_repairLocation!.latitude.toStringAsFixed(5)}, '
                  '${_repairLocation!.longitude.toStringAsFixed(5)}',
            ),
            if (_distanceText != null) ...[
              const SizedBox(height: 4),
              _infoRow('Distance', _distanceText!),
            ],
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _gettingLocation ? null : _captureLocation,
              icon: _gettingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(
                _repairLocation == null
                    ? 'Use My Location'
                    : 'Refresh Location',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF14B8A6),
                side: const BorderSide(color: Color(0xFF14B8A6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}