import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/lime_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  bool _controllersReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersReady) {
      return;
    }
    final appState = AppScope.of(context);
    _weightController.text = appState.bodyWeightKg.round().toString();
    _heightController.text = appState.heightCm.round().toString();
    _controllersReady = true;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final user = appState.currentUser;
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 96 + topInset, 24, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ProfileHeader(),
                const SizedBox(height: 32),
                _AccountCard(
                  name: user?.name ?? 'FORMAI Athlete',
                  email: user?.email ?? '',
                  initials: user?.initials ?? 'AI',
                  imagePath: appState.profileImagePath,
                  onPickImage: _pickProfileImage,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileMetric(
                        value: '${appState.completedWorkoutCount}',
                        label: 'ANALYZED',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ProfileMetric(
                        value: '${appState.totalSetCount}',
                        label: 'SETS',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileMetric(
                        value: '${appState.totalRepCount}',
                        label: 'TOTAL REPS',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ProfileMetric(
                        value: appState.totalCaloriesBurned.toStringAsFixed(0),
                        label: 'KCAL',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _BodyMetricsPanel(
                  weightController: _weightController,
                  heightController: _heightController,
                  onSave: _saveMetrics,
                ),
                const SizedBox(height: 24),
                _ProfileSwitch(
                  title: 'Metric units',
                  subtitle: 'Show kilograms and centimeters',
                  value: appState.metricUnits,
                  onChanged: appState.toggleMetricUnits,
                ),
                const SizedBox(height: 12),
                _ProfileSwitch(
                  title: 'Voice feedback',
                  subtitle: 'Hear coaching prompts during analysis',
                  value: appState.voiceFeedback,
                  onChanged: appState.toggleVoiceFeedback,
                ),
                const SizedBox(height: 28),
                LimeButton(
                  label: 'SIGN OUT',
                  icon: Icons.logout,
                  onPressed: appState.signOut,
                ),
                const SizedBox(height: 12),
                _DangerButton(
                  label: 'DELETE MY ACCOUNT',
                  icon: Icons.delete_forever_outlined,
                  onPressed: _deleteAccount,
                ),
              ],
            ),
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _ProfileTopBar()),
      ],
    );
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 900,
    );
    if (image == null || !mounted) {
      return;
    }
    await AppScope.of(context).updateProfileImagePath(image.path);
  }

  Future<void> _saveMetrics() async {
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    if (weight == null || height == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.panel,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Enter valid body weight and height.',
              style: TextStyle(color: AppColors.text),
            ),
          ),
        );
      return;
    }
    await AppScope.of(
      context,
    ).updateBodyMetrics(bodyWeightKg: weight, heightCm: height);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.panel,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Body metrics saved.',
            style: TextStyle(color: AppColors.text),
          ),
        ),
      );
  }

  Future<void> _deleteAccount() async {
    final appState = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text(
            'Delete account?',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'This removes your account, saved workouts, stats, profile picture link, and workout reminders from this device.',
            style: TextStyle(color: AppColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.alert),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await appState.deleteAccount();
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.imagePath,
    required this.onPickImage,
  });

  final String name;
  final String email;
  final String initials;
  final String? imagePath;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final imageFile = imagePath == null ? null : File(imagePath!);
    final hasImage = imageFile != null && imageFile.existsSync();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.lime.withValues(alpha: 0.12),
                backgroundImage: hasImage ? FileImage(imageFile) : null,
                child: hasImage
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.lime,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onPickImage,
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.buttonText,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.slate, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72 + topInset,
          padding: EdgeInsets.fromLTRB(24, 16 + topInset, 24, 16),
          color: AppColors.background.withValues(alpha: 0.62),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FormaiWordmark(size: 20),
              Icon(Icons.person_outline, color: AppColors.limeAlt),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyMetricsPanel extends StatelessWidget {
  const _BodyMetricsPanel({
    required this.weightController,
    required this.heightController,
    required this.onSave,
  });

  final TextEditingController weightController;
  final TextEditingController heightController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BODY METRICS',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricInput(
                  controller: weightController,
                  label: 'WEIGHT',
                  suffix: 'kg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricInput(
                  controller: heightController,
                  label: 'HEIGHT',
                  suffix: 'cm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LimeButton(
            label: 'SAVE METRICS',
            icon: Icons.monitor_weight_outlined,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _MetricInput extends StatelessWidget {
  const _MetricInput({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    cursorColor: AppColors.lime,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration.collapsed(hintText: ''),
                  ),
                ),
                Text(
                  suffix,
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROFILE',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 40 / 36,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'ACCOUNT, SESSION PREFERENCES, AND PROGRESS',
          style: TextStyle(
            color: AppColors.slate,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 118,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.lime,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSwitch extends StatelessWidget {
  const _ProfileSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.lime,
            activeTrackColor: AppColors.lime.withValues(alpha: 0.25),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.alert.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.alert, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.alert,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
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
