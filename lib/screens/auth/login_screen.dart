import 'package:Spicify/screens/auth/forgot_password.dart';
import 'package:Spicify/screens/auth/register_screen.dart';
import 'package:Spicify/screens/web_view_screen.dart';
import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utilities/app_colors.dart';
import '../../utilities/app_typography.dart';
import '../auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  void _handleLoginResult(AuthProvider authProvider, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.loginSuccess),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppColors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 5),

                  // Logo
                  Image.asset(
                    "asset/image/logo_new.png",
                    height: 150,
                    width: 150,
                    fit: BoxFit.fill,
                  ),

                  const SizedBox(height: 50),

                  // Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RepaintBoundary(
                      child: Text(
                        l10n.loginTitle,
                        style: AppTypography.heading16Bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    hintText: l10n.emailHint,
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    hintText: l10n.passwordHint,
                    obscureText: true,
                  ),

                  const SizedBox(height: 8),

                  // Remember me
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) =>
                            setState(() => _rememberMe = value!),
                        activeColor: AppColors.buttonRed,
                      ),
                      RepaintBoundary(
                          child: Text(l10n.rememberMe,
                              style: AppTypography.labelText)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Login Button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
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
                                      SnackBar(
                                          content:
                                              Text(l10n.fillAllFieldsError)),
                                    );
                                    return;
                                  }

                                  await authProvider.loginWithEmail(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                                  _handleLoginResult(authProvider, context);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: authProvider.isLoading
                                ? AppColors.buttonRed.withOpacity(0.7)
                                : AppColors.buttonRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
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
                                      child: Text(
                                        l10n.processingButton,
                                        style: AppTypography.buttonText,
                                      ),
                                    ),
                                  ],
                                )
                              : RepaintBoundary(
                                  child: Text(l10n.loginButton,
                                      style: AppTypography.buttonText),
                                ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        NavigationHelper.pushWithTransition(
                            context: context,
                            targetPage: ForgotPasswordScreen());
                      },
                      child: RepaintBoundary(
                        child: Text(l10n.forgotPassword,
                            style: AppTypography.linkText),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Text(l10n.orLoginWith, style: AppTypography.labelText),
                  // const SizedBox(height: 20),

                  // Social Login Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // _buildSocialLoginButton(
                      //   icon: FontAwesomeIcons.google,
                      //   onTap: () async {
                      //     await authProvider.loginWithGoogle(context);
                      //     _handleLoginResult(authProvider, context);
                      //   },
                      // ),
                      // _buildSocialLoginButton(
                      //   icon: FontAwesomeIcons.facebookF,
                      //   onTap: () async {
                      //     await authProvider.loginWithFacebook();
                      //     _handleLoginResult(authProvider, context);
                      //   },
                      // ),
                      // _buildSocialLoginButton(
                      //   icon: FontAwesomeIcons.twitter,
                      //   onTap: () async {
                      //     await authProvider.loginWithTwitter();
                      //     _handleLoginResult(authProvider, context);
                      //   },
                      // ),
                    ],
                  ),

                  //const Spacer(),

                  SizedBox(
                    height: 20,
                  ),

                  // // Register Link
                  GestureDetector(
                    onTap: () async {
                      // final uri =
                      //     Uri.parse("https://spicifyapp.com/auth/register");

                      NavigationHelper.pushWithTransition(
                          context: context,
                          targetPage: WebViewScreen(
                              url: "https://spicifyapp.com/auth/register"));

                      // final launched = await launchUrl(uri,
                      //     mode: LaunchMode.externalApplication);
                      // if (!launched && context.mounted) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     SnackBar(content: Text('Could not launch $uri')),
                      //   );
                      // }
                      //
                      // // if (await canLaunchUrl(uri)) {
                      // //   final launched = await launchUrl(uri,
                      // //       mode: LaunchMode.externalApplication);
                      // //   if (!launched && context.mounted) {
                      // //     ScaffoldMessenger.of(context).showSnackBar(
                      // //       SnackBar(content: Text('Could not launch $uri')),
                      // //     );
                      // //   }
                      // // } else {
                      // //   if (context.mounted) {
                      // //     print('URL not valid: $uri');
                      // //     ScaffoldMessenger.of(context).showSnackBar(
                      // //       SnackBar(content: Text('URL not valid: $uri')),
                      // //     );
                      // //   }
                      // // }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text.rich(
                        TextSpan(
                          text: l10n.noAccountPrompt,
                          style: AppTypography.labelText,
                          children: [
                            TextSpan(
                              text: l10n.registerLink,
                              style: AppTypography.linkText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildSocialLoginButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.white),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(child: FaIcon(icon, color: AppColors.white)),
      ),
    );
  }
}
