import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/report_draft.dart';
import '../../../models/report_model.dart';
import '../../../services/location_service.dart';
import '../../../utils/snackbar.dart';
import '../../../widgets/location_map.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/step_progress.dart';
import 'report_review_screen.dart';

class ReportLocationScreen extends StatefulWidget {
  final ReportDraft draft;

  const ReportLocationScreen({super.key, required this.draft});

  @override
  State<ReportLocationScreen> createState() => _ReportLocationScreenState();
}

class _ReportLocationScreenState extends State<ReportLocationScreen> {
  final _locationService = LocationService();

  ReportLocation? _location;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _location = widget.draft.location;
  }

  Future<void> _capture() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _locationService.getCurrentLocation();

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _location = result.location;
        _isLoading = false;
      });
      AppSnackbar.success(context, 'Location captured');
    } else {
      setState(() {
        _errorMessage = result.error;
        _isLoading = false;
      });
      AppSnackbar.error(context, result.error ?? 'Could not get location');
    }
  }

  void _onMapTap(ReportLocation newLoc) {
    setState(() {
      _location = ReportLocation(
        latitude: newLoc.latitude,
        longitude: newLoc.longitude,
        accuracy: _location?.accuracy,
      );
    });
  }

  void _continue() {
    if (_location == null) {
      AppSnackbar.error(context, 'Please capture your location first');
      return;
    }

    widget.draft.location = _location;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportReviewScreen(draft: widget.draft),
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
                    const StepProgress(currentStep: 3, totalSteps: 4),
                    const SizedBox(height: 24),

                    const Text(
                      'Where is it?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "We'll tag this report with your current location.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildMapArea(),

                    const SizedBox(height: 16),

                    if (_location != null)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tap anywhere on the map to adjust the pin.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    PrimaryButton(
                      label: _location == null
                          ? 'Use My Location'
                          : 'Refresh Location',
                      icon: Icons.my_location,
                      isLoading: _isLoading,
                      onPressed: _capture,
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _errorCard(_errorMessage!),
                    ],
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
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    // No location yet
    if (_location == null && !_isLoading) {
      return Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_searching,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No location captured',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tap the button below to capture your current location.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Loading
    if (_isLoading && _location == null) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Getting your location...',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Has location — show map
    return Column(
      children: [
        Stack(
          children: [
            LocationMap(
              location: _location!,
              height: 260,
              interactive: true,
              onLocationChanged: _onMapTap,
            ),
            // Accuracy chip overlay
            if (_location!.accuracy != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '±${_location!.accuracy!.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}