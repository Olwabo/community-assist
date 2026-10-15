import 'package:flutter/material.dart';

import '../../../constants/app_categories.dart';
import '../../../constants/app_colors.dart';
import '../../../models/report_draft.dart';
import '../../../utils/snackbar.dart';
import '../../../widgets/category_picker.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/step_progress.dart';
import 'report_photo_screen.dart';

class ReportCategoryScreen extends StatefulWidget {
  final ReportDraft draft;

  const ReportCategoryScreen({super.key, required this.draft});

  @override
  State<ReportCategoryScreen> createState() => _ReportCategoryScreenState();
}

class _ReportCategoryScreenState extends State<ReportCategoryScreen> {
  late ReportCategory? _selected;
  late final TextEditingController _descCtrl;

  static const int _maxDescLength = 500;

  @override
  void initState() {
    super.initState();
    _selected = widget.draft.category;
    _descCtrl = TextEditingController(text: widget.draft.description);
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    if (_selected == null) {
      AppSnackbar.error(context, 'Please select a category');
      return;
    }

    final desc = _descCtrl.text.trim();
    if (desc.length < 10) {
      AppSnackbar.error(
        context,
        'Description must be at least 10 characters',
      );
      return;
    }

    widget.draft.category = _selected;
    widget.draft.description = desc;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportPhotoScreen(draft: widget.draft),
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
                    const StepProgress(currentStep: 1, totalSteps: 4),
                    const SizedBox(height: 24),

                    const Text(
                      "What's the problem?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select the category that best describes the issue.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    CategoryPicker(
                      selected: _selected,
                      onSelected: (cat) => setState(() => _selected = cat),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Describe the issue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Include details like exact location, severity, or duration.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 5,
                      maxLength: _maxDescLength,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. Large pothole on Main Road near the traffic light. Water collects here when it rains and cars swerve to avoid it.',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky bottom button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
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
}