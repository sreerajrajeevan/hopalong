import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../data/sample_data.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

/// Signup: name, DOB (18+ enforced), gender, photo (mandatory),
/// mobile, optional email. Demo offers preset sample photos.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.state, this.prefill = const {}});

  final AppState state;
  final Map<String, dynamic> prefill;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _dob;
  String _gender = 'Female';
  String? _photoPath; // local file path
  String? _photoUrl; // preset sample avatar url
  String? _photoError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final contact = widget.prefill['contact'] as String? ?? '';
    _phoneController.text = contact;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _hasPhoto => _photoPath != null || _photoUrl != null;

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked =
          await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _photoPath = picked.path;
          _photoUrl = null;
          _photoError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not open the photo picker. Choose a sample photo below instead.')));
      }
    }
  }

  void _showPhotoSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      setState(() => _photoError = null);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick your date of birth.')));
      return;
    }
    if (!isAdult(_dob!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'HopAlong is for adults only — you must be 18 or older to join.')));
      return;
    }
    if (!_hasPhoto) {
      setState(() => _photoError = 'A profile photo is required to join.');
      return;
    }
    setState(() => _busy = true);
    final mode = widget.prefill['mode'] as String? ?? 'member';
    // A picked photo is uploaded to the avatars bucket first so the stored
    // avatarUrl is a public URL every phone can load — a local file path
    // would be meaningless on other users' phones and dies on reinstall.
    // If the upload fails, fall back to the local path and keep going;
    // the profile still gets created.
    var avatar = _photoUrl ??
        (_photoPath != null ? _photoPath! : sampleAvatars.first);
    if (_photoPath != null) {
      try {
        final uid = widget.state.repo.currentUserId ?? '';
        avatar = await widget.state.repo
            .uploadAvatar(uid, XFile(_photoPath!));
      } catch (_) {
        // Keep the local path as the avatar; the avatar widget falls back
        // to initials if the file is ever missing.
      }
    }
    final profile = Profile(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: _nameController.text.trim(),
      dob: _dob!,
      gender: _gender,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      avatarUrl: avatar,
      mode: mode,
    );
    try {
      await widget.state.repo.createProfile(profile);
      await widget.state.init();
      if (mounted) {
        // Clear the whole auth stack: back from home must exit the app,
        // never return to the phone/OTP screens.
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (_) => false);
      }
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not create your account. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tell us about you',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              const Text(
                  'Everyone on HopAlong has a real photo and is 18 or older. '
                  'That is what keeps our community friendly and safe.',
                  style: TextStyle(color: HopColors.inkSoft)),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    if (_photoPath != null)
                      CircleAvatar(
                          radius: 52,
                          backgroundImage: FileImage(File(_photoPath!)))
                    else if (_photoUrl != null)
                      HopAvatar(
                          photoUrl: _photoUrl!,
                          name: _nameController.text.isEmpty
                              ? 'You'
                              : _nameController.text,
                          radius: 52)
                    else
                      const CircleAvatar(
                        radius: 52,
                        backgroundColor: HopColors.sageSoft,
                        child: Icon(Icons.person_rounded,
                            size: 52, color: HopColors.sage),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showPhotoSheet,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                              color: HopColors.sage, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                    onPressed: _showPhotoSheet,
                    child: const Text('Add a profile photo *')),
              ),
              if (_photoError != null)
                Center(
                    child: Text(_photoError!,
                        style: const TextStyle(color: HopColors.danger))),
              const SizedBox(height: 8),
              const Text('Or pick a sample photo (demo only):',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: HopColors.inkSoft)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: sampleAvatars
                    .map((url) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setState(() {
                              _photoUrl = url;
                              _photoPath = null;
                              _photoError = null;
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _photoUrl == url
                                        ? HopColors.sage
                                        : Colors.transparent,
                                    width: 3),
                              ),
                              child: HopAvatar(
                                  photoUrl: url, name: 'Sample', radius: 22),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Full name *',
                    prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: (v) => v == null || v.trim().length < 2
                    ? 'Please enter your full name.'
                    : null,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(now.year - 25, now.month, now.day),
                    firstDate: DateTime(now.year - 100),
                    lastDate: now,
                  );
                  if (picked != null) {
                    setState(() => _dob = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Date of birth *',
                      prefixIcon: Icon(Icons.cake_outlined)),
                  child: Text(_dob == null
                      ? 'Tap to pick your birthday'
                      : formatDate(_dob!)),
                ),
              ),
              if (_dob != null && !isAdult(_dob!))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                      'You must be 18 or older to join HopAlong.',
                      style: TextStyle(color: HopColors.danger)),
                ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: Icon(Icons.people_outline_rounded)),
                items: const [
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(
                      value: 'Non-binary', child: Text('Non-binary')),
                  DropdownMenuItem(
                      value: 'Prefer not to say',
                      child: Text('Prefer not to say')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'Female'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Mobile number *',
                    prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => v == null || v.trim().length < 10
                    ? 'Enter a valid mobile number.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email address (optional)',
                    prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(v.trim())
                      ? null
                      : 'That email doesn\'t look right.';
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create my account'),
              ),
              const SizedBox(height: 12),
              const Text(
                'By joining you agree to be kind, show up on time, and '
                'follow the Community Guidelines. We never show your phone '
                'number publicly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: HopColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
