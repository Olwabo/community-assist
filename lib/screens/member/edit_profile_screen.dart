import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _populate(UserModel user) {
    if (_initialized) return;
    _firstNameCtrl.text = user.firstName;
    _lastNameCtrl.text = user.lastName;
    _phoneCtrl.text = user.phone;
    _initialized = true;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _auth.updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      if (!mounted) return;
      AppSnackbar.success(context, 'Profile updated');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Update failed: $e');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _auth.streamCurrentUser(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            _populate(user);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _firstNameCtrl,
                            label: 'First Name',
                            prefixIcon: Icons.person_outline,
                            validator: (v) =>
                                Validators.name(v, field: 'First name'),
                          ),
                          AppTextField(
                            controller: _lastNameCtrl,
                            label: 'Last Name',
                            prefixIcon: Icons.person_outline,
                            validator: (v) =>
                                Validators.name(v, field: 'Last name'),
                          ),
                          AppTextField(
                            controller: _phoneCtrl,
                            label: 'Phone Number',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppColors.warning,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Email cannot be changed. Contact support if needed.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: PrimaryButton(
                    label: 'Save Changes',
                    icon: Icons.check,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}