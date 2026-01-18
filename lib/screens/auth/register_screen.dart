import 'package:Spicify/screens/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../utilities/app_colors.dart';
import '../../utilities/app_typography.dart';
import '/gen_l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // Logo and App Name
                Image.asset(
                  "asset/image/logo_new.png",
                  height: 120,
                  width: 120,
                  fit: BoxFit.fill,
                ),

                const SizedBox(height: 50),

                Align(
                  alignment: Alignment.centerLeft,
                  child: RepaintBoundary(
                      child: Text(l10n.registerLink,
                          style: AppTypography.heading16Bold)),
                ),

                const SizedBox(height: 20),

                // Email
                _buildTextField(
                    controller: _emailController, hintText: l10n.email),
                const SizedBox(height: 16),

                // Password
                _buildTextField(
                    controller: _passwordController,
                    hintText: l10n.passwordHint,
                    obscureText: true),
                const SizedBox(height: 16),

                // Date of Birth
                _buildTextField(
                    controller: _dobController, hintText: l10n.dateBirth),
                const SizedBox(height: 24),

                // Terms
                RepaintBoundary(
                  child: Text(
                    l10n.registerLink,
                    textAlign: TextAlign.left,
                    style: AppTypography.hintText,
                  ),
                ),

                const SizedBox(height: 24),

                // Register Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final l10n = AppLocalizations.of(context)!;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();

                                if (_emailController.text.isEmpty ||
                                    _passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.fillAllFields)),
                                  );
                                  return;
                                }

                                try {
                                  await authProvider.registerUser(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                    name: '',
                                  );

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.registrationSuccess),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(authProvider.errorMessage ??
                                          l10n.registrationFailed),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: authProvider.isLoading
                              ? AppColors.buttonRed.withOpacity(0.7)
                              : AppColors.buttonRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                          shadowColor: AppColors.buttonRed.withOpacity(0.3),
                        ),
                        child: authProvider.isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  RepaintBoundary(
                                    child: Text(l10n.processing,
                                        style: AppTypography.buttonText),
                                  ),
                                ],
                              )
                            : RepaintBoundary(
                                child: Text(l10n.registerTitle,
                                    style: AppTypography.buttonText),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: RepaintBoundary(
                        child:
                            Text(l10n.cancel, style: AppTypography.buttonText)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: AppTypography.labelText,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textFieldGrey,
        hintText: hintText,
        hintStyle: AppTypography.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
