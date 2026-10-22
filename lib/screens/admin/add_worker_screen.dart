import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class AddWorkerScreen extends StatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.text = _generatePassword();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rand = Random();
    final letters = List.generate(
      3,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    final digits = (1000 + rand.nextInt(9000)).toString();
    return 'Worker$letters@$digits';
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final worker = await _auth.createWorkerAccount(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        temporaryPassword: _passwordCtrl.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _CredentialsDialog(
          worker: worker,
          password: _passwordCtrl.text,
          auth: _auth,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already registered';
          break;
        case 'invalid-email':
          msg = 'The email address is invalid';
          break;
        case 'weak-password':
          msg = 'Password is too weak';
          break;
        default:
          msg = e.message ?? 'Could not create worker';
      }
      AppSnackbar.error(context, msg);
      setState(() => _isCreating = false);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Worker')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF14B8A6),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Create an account for a maintenance worker. '
                                'You will receive credentials to share with them.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      AppTextField(
                        controller: _firstNameCtrl,
                        label: 'First Name',
                        hint: 'e.g. Sipho',
                        prefixIcon: Icons.person_outline,
                        validator: (v) =>
                            Validators.name(v, field: 'First name'),
                        textInputAction: TextInputAction.next,
                      ),
                      AppTextField(
                        controller: _lastNameCtrl,
                        label: 'Last Name',
                        hint: 'e.g. Nkosi',
                        prefixIcon: Icons.person_outline,
                        validator: (v) =>
                            Validators.name(v, field: 'Last name'),
                        textInputAction: TextInputAction.next,
                      ),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'worker@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        textInputAction: TextInputAction.next,
                      ),
                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        hint: '+27 82 123 4567',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      AppTextField(
                        controller: _passwordCtrl,
                        label: 'Temporary Password',
                        hint: 'Auto-generated',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: Validators.password,
                        textInputAction: TextInputAction.done,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Show/Hide',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Regenerate',
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: () {
                                setState(() {
                                  _passwordCtrl.text = _generatePassword();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
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
                label: 'Create Worker Account',
                icon: Icons.person_add_alt_1,
                isLoading: _isCreating,
                onPressed: _create,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialsDialog extends StatefulWidget {
  final UserModel worker;
  final String password;
  final AuthService auth;

  const _CredentialsDialog({
    required this.worker,
    required this.password,
    required this.auth,
  });

  @override
  State<_CredentialsDialog> createState() => _CredentialsDialogState();
}

class _CredentialsDialogState extends State<_CredentialsDialog> {
  bool _sendingEmail = false;

  Future<void> _sendResetEmail() async {
    setState(() => _sendingEmail = true);

    try {
      await widget.auth.sendPasswordResetTo(widget.worker.email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset email sent to ${widget.worker.email}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendingEmail = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send email: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _copyCredentials() async {
    final text =
        'Your CommunityAssist worker account:\n\n'
        'Email: ${widget.worker.email}\n'
        'Password: ${widget.password}\n\n'
        'Open CommunityAssist, log in, and change your password '
        'from Profile → Change Password.';

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credentials copied to clipboard'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: const [
          Icon(Icons.check_circle, color: AppColors.success, size: 24),
          SizedBox(width: 8),
          Text('Worker Created'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF14B8A6),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.worker.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.worker.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.worker.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'How do you want to give them access?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            _optionCard(
              icon: Icons.email_outlined,
              iconColor: AppColors.primary,
              title: 'Send Password Reset Email',
              subtitle: 'They will get a link to set their own password.',
              isRecommended: true,
              isLoading: _sendingEmail,
              onTap: _sendingEmail ? null : _sendResetEmail,
            ),

            const SizedBox(height: 10),

            _optionCard(
              icon: Icons.copy_outlined,
              iconColor: AppColors.accent,
              title: 'Copy Temporary Password',
              subtitle: 'Share via WhatsApp, SMS, or in person.',
              onTap: _copyCredentials,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _optionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isRecommended = false,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecommended
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.divider,
              width: isRecommended ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BEST',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}