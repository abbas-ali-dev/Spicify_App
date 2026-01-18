import 'dart:io';
import 'package:Spicify/utilities/app_typography.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_provider.dart' as my_auth;
import '../gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Editable fields
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _instController;
  late TextEditingController _ytController;
  late TextEditingController _tiktokController;
  String _imageUrl = "";
  File? _selectedImage;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadUserProfile();
      _initialized = true;
    }
  }

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _instController = TextEditingController();
    _ytController = TextEditingController();
    _tiktokController = TextEditingController();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final authP = Provider.of<my_auth.AuthProvider>(context, listen: false);
    authP.loadUserStatus();

    if (user == null) {
      setState(() {
        _error = l10n.userNotLoggedIn;
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['displayName'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';
        _phoneController.text = data['phone'] ?? '';
        _dobController.text = data['dob'] ?? '';
        _imageUrl = data['profileImage']?.toString().isNotEmpty == true
            ? data['profileImage']
            : 'asset/image/Image Placeholder 1.png';
        if (data['socialAccounts'] != null) {
          _instController.text = data['socialAccounts']['instagram'] ?? '';
          _ytController.text = data['socialAccounts']['youtube'] ?? '';
          _tiktokController.text = data['socialAccounts']['tiktok'] ?? '';
        }
      } else {
        _error = l10n.userProfileNotFound;
      }
    } catch (e) {
      print('error loading Profile ${e}');
      _error = l10n.failedToFetchUserData;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) return;

    setState(() => _isSaving = true);

    String uploadedImagePath = _imageUrl;

    // Upload if new image selected
    if (_selectedImage != null) {
      uploadedImagePath = await _uploadImage(_selectedImage!);
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'displayName': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'profileImage': uploadedImagePath,
        'socialAccounts': {
          // This updates only the socialAccounts field
          'instagram': _instController.text.trim(),
          'youtube': _ytController.text.trim(),
          'tiktok': _tiktokController.text.trim(),
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdatedSuccessfully)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${l10n.failedToSave}: ${e.toString()}")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    final uri = Uri.parse('https://inzi.genetum.com/bunnyupload');
    final request = http.MultipartRequest('POST', uri);
    final l10n = AppLocalizations.of(context)!;
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      return json['fileUrl'] ?? '';
    } else {
      throw Exception(l10n.imageUploadFailed);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1996, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')} ${_monthName(picked.month)} ${picked.year}";
      });
    }
  }

  String _monthName(int month) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december
    ];
    return months[month - 1];
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap}) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: RepaintBoundary(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )),
          Expanded(
            child: TextFormField(
              controller: controller,
              readOnly: readOnly || onTap != null,
              onTap: onTap,
              style: const TextStyle(color: Colors.white70),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                if (!readOnly && (value == null || value.trim().isEmpty)) {
                  return '${l10n.enter} $label';
                }
                return null;
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authP = Provider.of<my_auth.AuthProvider>(context);
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: RepaintBoundary(
              child: Text(l10n.profile,
                  style: const TextStyle(color: Colors.white))),
          centerTitle: true,
          actions: [
            if (!_isLoading)
              TextButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : RepaintBoundary(
                        child: Text(l10n.save,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ),
              )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  )
                : SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          authP.isSubscribed == true
                              ? RepaintBoundary(
                                  child: Text(
                                    "Hi ${_nameController.text} 👋 Ready to spice things up?",
                                    style: AppTypography.regular16Text,
                                  ),
                                )
                              : Container(),
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: _pickImage,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _selectedImage != null
                                  ? Image.file(
                                      _selectedImage!,
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: Uri.encodeFull(_imageUrl),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      // placeholder: (context, url) => Container(
                                      //   color: Colors.grey[200],
                                      //   child: const Center(child: CircularProgressIndicator()),
                                      // ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildField(l10n.displayName, _nameController),
                          _buildField(l10n.username, _usernameController),
                          _buildField(l10n.email, _emailController,
                              readOnly: true),
                          _buildField(l10n.phone, _phoneController),
                          _buildField(l10n.dateBirth, _dobController,
                              onTap: _selectDate),
                          const SizedBox(height: 30),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 20),
                              child: RepaintBoundary(
                                child: Text(
                                  l10n.socialAccounts,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildField(l10n.instagram, _instController),
                          _buildField(l10n.youtube, _ytController),
                          _buildField(l10n.tiktok, _tiktokController),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
