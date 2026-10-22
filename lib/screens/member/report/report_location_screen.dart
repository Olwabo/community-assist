import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/community_config.dart';
import '../../../models/report_draft.dart';
import '../../../models/report_model.dart';
import '../../../services/community_service.dart';
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
  final _communityService = CommunityService();

  ReportLocation? _location;
  String? _errorMessage;
  bool _isLoading = false;

  LocationCheckResult? _boundaryCheck;

  @override
  void initState() {
    super.initState();
    _location = widget.draft.location;
  }

  Future<void> _capture() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _boundaryCheck = null; // reset previous check
    });

    final result = await _locationService.getCurrentLocation();

    if (!mounted) return;

    if (result.isSuccess) {
      final loc = result.location!;

      // 1. Check community boundary
      final check = await _communityService.checkReportLocation(loc);
      if (!mounted) return;

      if (check == null) {
        setState(() {
          _errorMessage = 'Community configuration not found. Check internet connection.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _location = loc;
        _boundaryCheck = check;
        _isLoading = false;
      });

      if (check.isInside) {
        AppSnackbar.success(context, 'Location captured');
      } else {
        AppSnackbar.error(
          context,
          'You are outside the ${check.community.name} boundary',
        );
      }
    } else {
      setState(() {
        _errorMessage = result.error;
        _isLoading = false;
      });
      AppSnackbar.error(context, result.error ?? 'Could not get location');
    }
    
  }

  void _onMapTap(ReportLocation newLoc) async {
    final updated = ReportLocation(
      latitude: newLoc.latitude,
      longitude: newLoc.longitude,
      accuracy: _location?.accuracy,
    );

    setState(() => _location = updated);

    // Re-check boundary
    final check = await _communityService.checkReportLocation(updated);
    if (!mounted) return;

    setState(() => _boundaryCheck = check);
  }

  void _continue() {
    if (_location == null) {
      AppSnackbar.error(context, 'Please capture your location first');
      return;
    }

    if (_boundaryCheck != null && !_boundaryCheck!.isInside) {
      AppSnackbar.error(
        context,
        'You must be inside ${_boundaryCheck!.community.name} to submit a report',
      );
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
    final isOutside =
        _boundaryCheck != null && !_boundaryCheck!.isInside;

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

                    // Boundary status (inside/outside indicator)
                    if (_boundaryCheck != null) ...[
                      const SizedBox(height: 12),
                      _buildBoundaryStatus(),
                    ],

                    const SizedBox(height: 16),

                    if (_location != null && !isOutside)
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
                // Disable if outside boundary
                onPressed: isOutside ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOUNDARY STATUS INDICATOR
  // ============================================================

  Widget _buildBoundaryStatus() {
    final check = _boundaryCheck!;
    final isInside = check.isInside;
    final color = isInside ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isInside ? Icons.check_circle : Icons.location_off,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInside
                      ? 'Inside ${check.community.name}'
                      : 'Outside ${check.community.name}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${check.distanceKm.toStringAsFixed(1)} km from community center '
                  '(allowed: ${check.community.radiusKm.toInt()} km)',
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP AREA
  // ============================================================

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
    return Stack(
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
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

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