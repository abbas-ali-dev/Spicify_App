import 'package:Spicify/screens/notifications_screen.dart';
import 'package:Spicify/utilities/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/profile_screen.dart';
import '../utilities/change_selector.dart';
import '../utilities/navigator_helper_class.dart';
import 'auth/login_screen.dart';
import 'auth_provider.dart';

import '../gen_l10n/app_localizations.dart';

// ... other imports remain the same
class SettingsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SettingsScreen();
  }
}

void _showSocialAccountsDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final user = authProvider.currentUser;
  final data = await authProvider.loadUserProfile();
  TextEditingController instagramController =
      TextEditingController(text: data['instagram'] ?? '');
  TextEditingController youtubeController =
      TextEditingController(text: data['youtube'] ?? '');
  TextEditingController tiktokController =
      TextEditingController(text: data['tiktok'] ?? '');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.black,
        title: RepaintBoundary(
            child: Text(l10n.socialAccounts,
                style: TextStyle(color: Colors.white))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSocialAccountField(
                context,
                controller: instagramController,
                label: l10n.instagram,
                hint: l10n.enterInstagramUrl,
                icon: Icons.camera_alt,
              ),
              SizedBox(height: 16),
              _buildSocialAccountField(
                context,
                controller: youtubeController,
                label: l10n.youtube,
                hint: l10n.enterYoutubeUrl,
                icon: Icons.video_library,
              ),
              SizedBox(height: 16),
              _buildSocialAccountField(
                context,
                controller: tiktokController,
                label: l10n.tiktok,
                hint: l10n.enterTiktokUrl,
                icon: Icons.music_note,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(l10n.cancel, style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(l10n.save, style: TextStyle(color: Colors.green)),
            onPressed: () async {
              final socialAccounts = {
                'instagram': instagramController.text.trim(),
                'youtube': youtubeController.text.trim(),
                'tiktok': tiktokController.text.trim(),
              };

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .update({
                  'socialAccounts': socialAccounts,
                });

                // Update local user data
                //authProvider.updateUserSocialAccounts(socialAccounts);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.socialAccountsUpdated)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      );
    },
  );
}

Widget _buildSocialAccountField(
  BuildContext context, {
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
}) {
  final l10n = AppLocalizations.of(context)!;

  return TextFormField(
    controller: controller,
    style: TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white70),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white30),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    ),
    validator: (value) {
      if (value != null &&
          value.isNotEmpty &&
          !Uri.tryParse(value)!.isAbsolute) {
        return l10n.invalidUrl;
      }
      return null;
    },
  );
}

Widget _buildSocialAccountTile(
    BuildContext context, String? url, IconData icon, String label) {
  if (url == null || url.isEmpty) return SizedBox();

  return ListTile(
    leading: Icon(icon, color: Colors.white),
    title: RepaintBoundary(
        child: Text(label, style: TextStyle(color: Colors.white))),
    trailing: Icon(Icons.open_in_new, color: Colors.white70, size: 20),
    onTap: () async {
      final uri = Uri.parse(url);
      await launchUrl(uri);
      // if (await canLaunchUrl(uri)) {
      //   await launchUrl(uri);
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Could not launch $url')),
      //   );
      // }
    },
  );
}

class _SettingsScreen extends State<SettingsScreen> {
  final List<String> languages = [
    'English',
    'Urdu',
    'Spanish',
    'French',
    'Arabic'
  ];
  int selectedIndex = 0;

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardGrey,
        title: RepaintBoundary(
            child: Text(title, style: const TextStyle(color: Colors.white))),
        content: ConstrainedBox(
          constraints:
              const BoxConstraints(maxHeight: 300), // adjust height as needed
          child: SingleChildScrollView(
            child: RepaintBoundary(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: RepaintBoundary(
                child:
                    const Text('Close', style: TextStyle(color: Colors.red))),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? socialAccounts; //data['socialAccounts'] ?? {};

  late String privacyPolicy;
  late String aboutPolicy;
  late String termsOfService;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.loadUserStatus();
      final data = await auth.loadUserProfile();
      final pp = await auth.getPrivacyPolicy();
      final tt = await auth.getTerms();
      final about = await auth.getAbout();
      final accountData = await auth.getSocialAccounts();
      setState(() {
        socialAccounts = accountData; //data['socialAccounts'] ?? {};
        privacyPolicy = pp;
        termsOfService = tt;
        aboutPolicy = about;
      });
    });
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardGrey,
        title: RepaintBoundary(
            child: Text(l10n.deleteAccount,
                style: TextStyle(color: Colors.white))),
        content: Text(
          l10n.deleteAccountConfirmation,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: Text(l10n.cancel, style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child:
                Text(l10n.deleteAccount, style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete user data from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .delete();

        // Delete user from Firebase Auth
        await user?.delete();

        // Logout and navigate to login screen
        await authProvider.logout();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accountDeletedSuccessfully)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: RepaintBoundary(
            child: Text(l10n.settingsTitle,
                style: const TextStyle(color: Colors.white)),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const Divider(color: Colors.white10),
              if (user != null)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: RepaintBoundary(
                          child: Text(l10n.userDataNotFound,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    final name = data['name'] ?? 'User';
                    final email = data['email'] ?? '';
                    final imageUrl = (data['profileImage'] != null &&
                            data['profileImage'].toString().isNotEmpty)
                        ? data['profileImage']
                        : 'asset/image/Image Placeholder 1.png';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: GestureDetector(
                        onTap: () => NavigationHelper.pushWithTransition(
                            context: context, targetPage: ProfileScreen()),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: Uri.encodeFull(imageUrl),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                // placeholder: (context, url) => Container(
                                //   color: Colors.grey[200],
                                //   child: const Center(child: CircularProgressIndicator()),
                                // ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RepaintBoundary(
                                  child: Text(name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ),
                                const SizedBox(height: 4),
                                RepaintBoundary(
                                  child: SizedBox(
                                    child: Text(
                                      email,
                                      style: const TextStyle(
                                          color: Colors.white70),
                                      maxLines: 2,
                                      overflow: TextOverflow.clip,
                                    ),
                                    width: 180,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const Divider(color: Colors.white10),

              // Add Social Accounts ListTile
              ListTile(
                title: RepaintBoundary(
                  child: Text(l10n.socialAccounts,
                      style: TextStyle(color: Colors.white)),
                ),
                //onTap: _showSocialAccountsDialog,
              ),
              const Divider(color: Colors.white10),

              // Display existing social accounts if they exist
              _buildSocialAccountTile(
                context,
                socialAccounts?['instagram'] ?? '',
                Icons.camera_alt,
                l10n.instagram,
              ),

              if (socialAccounts?['instagram'] != null)
                const Divider(color: Colors.white10),

              _buildSocialAccountTile(
                context,
                socialAccounts?['youtube'] ?? '',
                Icons.video_library,
                l10n.youtube,
              ),

              if (socialAccounts?['youtube'] != null)
                const Divider(color: Colors.white10),

              _buildSocialAccountTile(
                context,
                socialAccounts?['tiktok'] ?? '',
                Icons.music_note,
                l10n.tiktok,
              ),
              if (socialAccounts?['tiktok'] != null)
                const Divider(color: Colors.white10),

              _buildSocialAccountTile(
                context,
                socialAccounts?['facebook'] ?? '',
                Icons.facebook,
                'Facebook',
              ),

              if (socialAccounts?['facebook'] != null)
                const Divider(color: Colors.white10),

              ...[
                l10n.notifications,
                l10n.changeLanguage,
                l10n.subscriptionStatus,
                l10n.termsOfService,
                l10n.privacyPolicy,
                l10n.aboutApp,
              ].map((setting) => Column(
                    children: [
                      ListTile(
                        title: RepaintBoundary(
                          child: Text(setting,
                              style: const TextStyle(color: Colors.white)),
                        ),
                        onTap: () {
                          if (setting == l10n.changeLanguage) {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black54,
                              builder: (_) => LanguageDialog(),
                            );
                          } else if (setting == l10n.notifications) {
                            NavigationHelper.pushWithTransition(
                                context: context,
                                targetPage: NotificationsScreen());
                          } else if (setting == l10n.subscriptionStatus) {
                            _showInfoDialog(
                                context,
                                l10n.subscriptionStatus,
                                authProvider.isSubscribed == true
                                    ? '👑 Premium Subscriber'
                                    : 'Free User.');
                          } else if (setting == l10n.termsOfService) {
                            _showInfoDialog(
                                context, l10n.termsOfService, termsOfService);
                          } else if (setting == l10n.privacyPolicy) {
                            _showInfoDialog(
                                context, l10n.privacyPolicy, privacyPolicy);
                          } else if (setting == l10n.aboutApp) {
                            _showInfoDialog(
                                context, l10n.aboutApp, aboutPolicy);
                          }
                        },
                      ),
                      const Divider(color: Colors.white10),
                    ],
                  )),
              //const Spacer(),

              if (user != null) ...[
                const Divider(color: Colors.white10),
                ListTile(
                  title: RepaintBoundary(
                    child: Text(
                      l10n.deleteAccount,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  onTap: () => _deleteAccount(context),
                ),
                const Divider(color: Colors.white10),
              ],

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      if (user != null) {
                        await authProvider.logout();
                      } else {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      }
                    },
                    child: RepaintBoundary(
                      child: Text(
                        user != null ? l10n.logout : l10n.loginTitle,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
