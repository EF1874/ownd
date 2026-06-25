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

  Widget _buildAvatarCard(String? avatarPath) {
    return BaseCard(
      child: Row(
        children: [
          _buildAvatar(avatarPath, 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('头像', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  avatarPath == null ? '还没有设置头像' : '已设置头像',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isUploadingAvatar ? null : _pickAvatar,
            child: _isUploadingAvatar
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('更换'),
          ),
          if (avatarPath != null)
            IconButton(
              tooltip: '移除头像',
              onPressed: _isUploadingAvatar ? null : _deleteAvatar,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }

  Widget _buildNameCard() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: '用户名',
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            onSubmitted: (_) => _saveName(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSavingName ? null : _saveName,
            child: _isSavingName
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存用户名'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard(String currentEmail) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('当前邮箱'),
          const SizedBox(height: 4),
          Text(
            currentEmail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '新邮箱',
              errorText: _emailError,
            ),
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _emailCodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '验证码',
                    errorText: _emailCodeError,
                  ),
                  onChanged: (_) {
                    if (_emailCodeError != null) {
                      setState(() => _emailCodeError = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextButton(
                  onPressed: (_isSendingEmailCode || _emailCountdown > 0)
                      ? null
                      : _sendEmailCode,
                  child: _isSendingEmailCode
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _emailCountdown > 0
                              ? '$_emailCountdown 秒后重发'
                              : '获取验证码',
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _passwordField(
            controller: _emailPasswordController,
            focusNode: _emailPasswordFocusNode,
            label: '当前密码',
            visible: _showEmailPassword,
            errorText: _emailPasswordError,
            onChanged: (_) {
              if (_emailPasswordError != null) {
                setState(() => _emailPasswordError = null);
              }
            },
            onToggle: () =>
                setState(() => _showEmailPassword = !_showEmailPassword),
          ),
          _feedbackText(_emailFeedback, isError: _emailFeedbackIsError),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSavingEmail ? null : () => _saveEmail(currentEmail),
            child: _isSavingEmail
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存邮箱'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _passwordField(
            controller: _currentPasswordController,
            focusNode: _currentPasswordFocusNode,
            label: '当前密码',
            visible: _showCurrentPassword,
            errorText: _currentPasswordError,
            textInputAction: TextInputAction.next,
            onSubmitted: () => _focusPasswordField(_newPasswordFocusNode),
            onChanged: (_) {
              if (_currentPasswordError != null) {
                setState(() => _currentPasswordError = null);
              }
            },
            onToggle: () =>
                setState(() => _showCurrentPassword = !_showCurrentPassword),
          ),
          const SizedBox(height: 12),
          _passwordField(
            controller: _newPasswordController,
            focusNode: _newPasswordFocusNode,
            label: '新密码',
            visible: _showNewPassword,
            errorText: _newPasswordError,
            textInputAction: TextInputAction.next,
            onSubmitted: () => _focusPasswordField(_confirmPasswordFocusNode),
            onChanged: (_) {
              if (_newPasswordError != null) {
                setState(() => _newPasswordError = null);
              }
            },
            onToggle: () =>
                setState(() => _showNewPassword = !_showNewPassword),
          ),
          const SizedBox(height: 12),
          _passwordField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: '确认新密码',
            visible: _showConfirmPassword,
            errorText: _confirmPasswordError,
            onSubmitted: _savePassword,
            onChanged: (_) {
              if (_confirmPasswordError != null) {
                setState(() => _confirmPasswordError = null);
              }
            },
            onToggle: () =>
                setState(() => _showConfirmPassword = !_showConfirmPassword),
          ),
          _feedbackText(_passwordFeedback, isError: _passwordFeedbackIsError),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSavingPassword ? null : _savePassword,
            child: _isSavingPassword
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存密码'),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    String? errorText,
    TextInputAction textInputAction = TextInputAction.done,
    VoidCallback? onSubmitted,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !visible,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            onToggle();
            focusNode.requestFocus();
          },
        ),
      ),
    );
  }

  Widget _feedbackText(String? message, {required bool isError}) {
    if (message == null) return const SizedBox.shrink();

    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(message, style: TextStyle(color: color)),
    );
  }

  Widget _buildAvatar(String? avatarPath, double size) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.account_circle_outlined,
          size: size * 0.58,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarPath == null
            ? fallback
            : AppImage(path: avatarPath, width: size, height: size),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  bool get _hasEmailInput {
    return _emailController.text.trim().isNotEmpty ||
        _emailCodeController.text.trim().isNotEmpty ||
        _emailPasswordController.text.isNotEmpty;
  }

  bool get _hasPasswordInput {
    return _currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
  }

  bool get _hasUnsavedChanges {
    if (!mounted) return false;

    final user = ref.read(authControllerProvider).asData?.value?.user;
    if (user == null) return false;

    final currentName = user.name ?? user.email;
    return _nameController.text.trim() != currentName.trim() ||
        _hasEmailInput ||
        _hasPasswordInput;
  }

  Future<bool> _confirmLeave() async {
    if (!mounted) return true;

    if (_isSavingName || _isSavingEmail || _isSavingPassword) {
      AppToast.show(context, '正在保存，请稍候');
      return false;
    }

    if (!_hasUnsavedChanges) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('放弃未保存的修改？'),
        content: const Text('离开后，这些输入不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('放弃离开'),
          ),
        ],
      ),
    );

    if (!mounted) return true;
    return leave ?? false;
  }

  Future<void> _leaveAccountPage() async {
    if (!await _confirmLeave()) return;
    if (!mounted) return;

    context.go('/profile');
  }

  void _focusPasswordField(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  String? _emailValidationError(String email) {
    return email.isEmpty || !email.contains('@') ? '请输入有效邮箱' : null;
  }

  void _setEmailFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _emailFeedback = message;
      _emailFeedbackIsError = isError;
    });
    AppToast.show(context, message, isError: isError);
  }

  void _setPasswordFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _passwordFeedback = message;
      _passwordFeedbackIsError = isError;
    });
    AppToast.show(context, message, isError: isError);
  }

  void _returnToProfile(String message) {
    if (!mounted) return;
    AppToast.show(context, message);
    context.go('/profile');
  }

  Future<void> _pickAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      final file = await ref
          .read(imageServiceProvider)
          .pickAndCropImage(
            context: context,
            source: ImageSource.gallery,
            isSquare: true,
          );
      if (file == null) return;
      await ref.read(authControllerProvider.notifier).uploadAvatar(file.path);
      _returnToProfile('头像已更新');
    } catch (e) {
      if (mounted) {
        AppToast.show(context, '头像更新失败: ${userErrorMessage(e)}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _deleteAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(authControllerProvider.notifier).deleteAvatar();
      _returnToProfile('头像已移除');
    } catch (e) {
      if (mounted) {
        AppToast.show(context, '头像移除失败: ${userErrorMessage(e)}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = '请输入用户名');
      AppToast.show(context, '请输入用户名', isError: true);
      return;
    }

    setState(() {
      _isSavingName = true;
      _nameError = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(name: name);
      _returnToProfile('用户名已更新');
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '用户名保存失败: ${userErrorMessage(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _sendEmailCode() async {
    final email = _emailController.text.trim();
    final emailError = _emailValidationError(email);
    if (emailError != null) {
      setState(() {
        _emailError = emailError;
        _emailFeedback = emailError;
        _emailFeedbackIsError = true;
      });
      AppToast.show(context, emailError, isError: true);
      return;
    }

    setState(() {
      _isSendingEmailCode = true;
      _emailError = null;
      _emailFeedback = '正在发送验证码...';
      _emailFeedbackIsError = false;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendVerificationCode(email, type: 'change-email');
      _startEmailCountdown();
      _setEmailFeedback('验证码已发送，请检查新邮箱');
    } catch (e) {
      _setEmailFeedback('验证码发送失败：${userErrorMessage(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _isSendingEmailCode = false);
    }
  }

  Future<void> _saveEmail(String currentEmail) async {
    final email = _emailController.text.trim();
    final code = _emailCodeController.text.trim();
    final password = _emailPasswordController.text;
    final emailError =
        _emailValidationError(email) ??
        (email == currentEmail ? '请输入新的邮箱' : null);
    final codeError = code.isEmpty ? '请输入验证码' : null;
    final passwordError = password.isEmpty ? '请输入当前密码' : null;
    final firstError = emailError ?? codeError ?? passwordError;

    if (firstError != null) {
      setState(() {
        _emailError = emailError;
        _emailCodeError = codeError;
        _emailPasswordError = passwordError;
        _emailFeedback = firstError;
        _emailFeedbackIsError = true;
      });
      AppToast.show(context, firstError, isError: true);
      return;
    }

    setState(() {
      _isSavingEmail = true;
      _emailError = null;
      _emailCodeError = null;
      _emailPasswordError = null;
      _emailFeedback = '正在保存邮箱...';
      _emailFeedbackIsError = false;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changeEmail(email: email, password: password, code: code);
      _emailController.clear();
      _emailCodeController.clear();
      _emailPasswordController.clear();
      _emailTimer?.cancel();
      _emailTimer = null;
      _emailCountdown = 0;
      _emailCodeEndTime = null;
      _returnToProfile('邮箱已更新');
    } catch (e) {
      _setEmailFeedback('邮箱保存失败：${userErrorMessage(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingEmail = false);
    }
  }

  Future<void> _savePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final currentPasswordError = currentPassword.isEmpty ? '请输入当前密码' : null;
    final newPasswordError = newPassword.length < 6 ? '密码至少 6 位' : null;
    final confirmPasswordError = newPassword != confirmPassword
        ? '两次输入的密码不一致'
        : null;
    final firstError =
        currentPasswordError ?? newPasswordError ?? confirmPasswordError;

    if (firstError != null) {
      setState(() {
        _currentPasswordError = currentPasswordError;
        _newPasswordError = newPasswordError;
        _confirmPasswordError = confirmPasswordError;
        _passwordFeedback = firstError;
        _passwordFeedbackIsError = true;
      });
      AppToast.show(context, firstError, isError: true);
      return;
    }

    setState(() {
      _isSavingPassword = true;
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
      _passwordFeedback = '正在保存密码...';
      _passwordFeedbackIsError = false;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _returnToProfile('密码已更新');
    } catch (e) {
      _setPasswordFeedback('密码保存失败：${userErrorMessage(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  void _startEmailCountdown() {
    _emailCodeEndTime = DateTime.now().add(const Duration(seconds: 60));
    setState(() => _emailCountdown = 60);
    _emailTimer?.cancel();
    _emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateEmailCountdown();
    });
  }

  void _updateEmailCountdown() {
    if (_emailCodeEndTime == null) return;
    final remaining = _emailCodeEndTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      setState(() {
        _emailCountdown = 0;
        _emailCodeEndTime = null;
        _emailTimer?.cancel();
        _emailTimer = null;
      });
      return;
    }
    setState(() => _emailCountdown = remaining);
  }
}
