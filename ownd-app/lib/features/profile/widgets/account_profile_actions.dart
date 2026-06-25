// ignore_for_file: invalid_use_of_protected_member

part of '../account_profile_screen.dart';

extension _AccountProfileActions on _AccountProfileScreenState {
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
