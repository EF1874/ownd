import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/error_messages.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/auth_controller.dart';
import '../../shared/services/image_service.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/base_card.dart';

part 'widgets/account_profile_sections.dart';
part 'widgets/account_profile_actions.dart';

class AccountProfileScreen extends ConsumerStatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  ConsumerState<AccountProfileScreen> createState() =>
      _AccountProfileScreenState();
}

class _AccountProfileScreenState extends ConsumerState<AccountProfileScreen>
    with WidgetsBindingObserver {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _scrollController = ScrollController();
  final _emailPasswordFocusNode = FocusNode();
  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  String? _loadedUserId;
  bool _isSavingName = false;
  bool _isUploadingAvatar = false;
  bool _isSendingEmailCode = false;
  bool _isSavingEmail = false;
  bool _isSavingPassword = false;
  bool _showEmailPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _nameError;
  String? _emailError;
  String? _emailCodeError;
  String? _emailPasswordError;
  String? _emailFeedback;
  bool _emailFeedbackIsError = false;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _passwordFeedback;
  bool _passwordFeedbackIsError = false;
  int _emailCountdown = 0;
  DateTime? _emailCodeEndTime;
  Timer? _emailTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _emailPasswordFocusNode.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateEmailCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value?.user;

    if (user != null && _loadedUserId != user.id) {
      _loadedUserId = user.id;
      _nameController.text = user.name ?? user.email;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leaveAccountPage();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _leaveAccountPage),
          title: const Text('账号资料'),
        ),
        body: user == null
            ? const Center(child: Text('请先登录'))
            : SafeArea(
                top: false,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildAvatarCard(user.avatarPath),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, '用户名'),
                    const SizedBox(height: 8),
                    _buildNameCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, '邮箱'),
                    const SizedBox(height: 8),
                    _buildEmailCard(user.email),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, '密码'),
                    const SizedBox(height: 8),
                    _buildPasswordCard(),
                  ],
                ),
              ),
      ),
    );
  }
}
