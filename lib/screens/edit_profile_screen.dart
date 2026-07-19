import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../utils/spacings.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _selectedAvatarPath;
  String? _uploadedAvatarUrl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _uploadedAvatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 256, maxHeight: 256);
    if (picked == null) return;
    setState(() {
      _selectedAvatarPath = picked.path;
      _uploadedAvatarUrl = null;
    });
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacings.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(AppLocalizations.of(context)!.editProfileCamera),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(AppLocalizations.of(context)!.editProfileGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(String path) async {
    try {
      final api = context.read<ApiClient>();
      final response = await api.postMultipart(
        '/upload',
        fileField: 'file',
        filePath: path,
        queryParams: {'folder': 'avatars'},
      );
      final data = response['data'];
      if (data is Map<String, dynamic> && data['url'] is String) {
        return data['url'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _uploadedAvatarUrl;

      if (_selectedAvatarPath != null && avatarUrl == null) {
        setState(() => _isUploadingImage = true);
        avatarUrl = await _uploadImage(_selectedAvatarPath!);
        setState(() => _isUploadingImage = false);

        if (avatarUrl == null && mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.uploadFailed)),
          );
          return;
        }
      }

      final api = context.read<ApiClient>();
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
      };
      if (_phoneController.text.trim().isNotEmpty) {
        body['phone'] = _phoneController.text.trim();
      }
      if (avatarUrl != null) {
        body['avatar_url'] = avatarUrl;
      }

      final response = await api.put('/users/me/profile', body);
      if (!mounted) return;

      if (response['data'] != null) {
        final updated = AppUser.fromJson(response['data'] as Map<String, dynamic>);
        context.read<AuthProvider>().updateUser(updated);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.editProfileSaved)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.editProfileSaveError)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final user = context.watch<AuthProvider>().user;
    final loc = AppLocalizations.of(context)!;

    final displayAvatarUrl = _uploadedAvatarUrl;
    final displayAvatarPath = _selectedAvatarPath;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.editProfileTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacings.lg),
        children: [
          GestureDetector(
            onTap: _isUploadingImage ? null : _showImagePickerSheet,
            child: SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.curry,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.curry.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: displayAvatarPath != null
                          ? Image.file(File(displayAvatarPath), fit: BoxFit.cover)
                          : displayAvatarUrl != null
                              ? Image.network(ApiConfig.resolveUrl(displayAvatarUrl), fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    ((user?.name ?? '?').isEmpty ? '?' : user!.name).substring(0, 1).toUpperCase(),
                                    style: textTheme.displaySmall?.copyWith(
                                      color: colors.background,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.surfaceAlt, width: 2.5),
                      ),
                      child: _isUploadingImage
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.camera_alt_rounded, size: 16, color: context.colors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.editProfileNameLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? loc.editProfileNameRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: loc.editProfilePhoneLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: user?.email ?? '',
                  decoration: InputDecoration(
                    labelText: loc.editProfileEmailLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.background),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(loc.editProfileSave),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
