import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/context_colors.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../utils/spacings.dart';

Uint8List? _encodeAvatarJpeg(Uint8List rawBytes) {
  final decoded = img.decodeImage(rawBytes);
  return decoded == null ? null : img.encodeJpg(decoded, quality: 85);
}

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
    final picked =
        await _picker.pickImage(source: source, maxWidth: 256, maxHeight: 256);
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
      debugPrint('upload: converting $path to JPEG');
      final rawBytes = await File(path).readAsBytes();
      final jpgBytes = await compute(_encodeAvatarJpeg, rawBytes);
      if (jpgBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.uploadFailed)),
          );
        }
        return null;
      }
      final tmpFile = File('${Directory.systemTemp.path}/avatar_upload.jpg');
      await tmpFile.writeAsBytes(jpgBytes);
      debugPrint('upload: converted to JPEG, size=${jpgBytes.length}');
      if (!mounted) {
        await tmpFile.delete();
        return null;
      }

      final api = context.read<ApiClient>();
      final response = await api.postMultipart(
        '/upload',
        fileField: 'file',
        filePath: tmpFile.path,
        queryParams: {'folder': 'avatars'},
      );
      await tmpFile.delete();
      debugPrint('upload: response keys: ${response.keys}');
      final data = response['data'];
      if (data is Map<String, dynamic> && data['url'] is String) {
        return data['url'] as String;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.uploadFailed)),
        );
      }
      return null;
    } on Exception catch (e) {
      debugPrint('upload: exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.uploadFailed)),
        );
      }
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
        if (!mounted) return;
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
        final updated =
            AppUser.fromJson(response['data'] as Map<String, dynamic>);
        context.read<AuthProvider>().updateUser(updated);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.editProfileSaved)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.editProfileSaveError)),
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
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth < 360 ? Spacings.md : Spacings.lg,
            Spacings.lg,
            constraints.maxWidth < 360 ? Spacings.md : Spacings.lg,
            Spacings.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
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
                                      color: AppColors.curry
                                          .withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: AnimatedSwitcher(
                                    duration: AppMotion.duration(
                                      context,
                                      AppMotion.short,
                                    ),
                                    child: displayAvatarPath != null
                                        ? Image.file(
                                            File(displayAvatarPath),
                                            key: ValueKey(displayAvatarPath),
                                            cacheWidth: 256,
                                            fit: BoxFit.cover,
                                          )
                                        : displayAvatarUrl != null
                                            ? CachedNetworkImage(
                                                key: ValueKey(displayAvatarUrl),
                                                imageUrl: ApiConfig.resolveUrl(
                                                  displayAvatarUrl,
                                                ),
                                                memCacheWidth: (88 *
                                                        MediaQuery
                                                            .devicePixelRatioOf(
                                                                context))
                                                    .round(),
                                                fit: BoxFit.cover,
                                              )
                                            : Center(
                                                key: const ValueKey(
                                                  'edit-avatar-fallback',
                                                ),
                                                child: Text(
                                                  ((user?.name ?? '?').isEmpty
                                                          ? '?'
                                                          : user!.name)
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: textTheme.displaySmall
                                                      ?.copyWith(
                                                    color: colors.background,
                                                    fontWeight: FontWeight.w900,
                                                  ),
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
                                    border: Border.all(
                                        color: colors.surfaceAlt, width: 2.5),
                                  ),
                                  child: _isUploadingImage
                                      ? const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Icon(Icons.camera_alt_rounded,
                                          size: 16,
                                          color: context.colors.muted),
                                ),
                              ),
                            ],
                          ),
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
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: loc.editProfileNameLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline_rounded,
                                  color: colors.muted),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? loc.editProfileNameRequired
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: loc.editProfilePhoneLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone_outlined,
                                  color: colors.muted),
                            ),
                            keyboardType: TextInputType.phone,
                            scrollPadding: const EdgeInsets.all(80),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: user?.email ?? '',
                            style: TextStyle(color: colors.textSecondary),
                            decoration: InputDecoration(
                              labelText: loc.editProfileEmailLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: colors.muted),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? context.colors.background
                                            : Colors.white),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              _isSaving
                                  ? loc.editProfileSaving
                                  : loc.editProfileSave,
                            ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
