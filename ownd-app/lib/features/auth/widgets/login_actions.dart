// ignore_for_file: invalid_use_of_protected_member

part of '../login_screen.dart';

extension _LoginActions on _LoginScreenState {
  void _updateSignupCountdown() {
    if (_signupEndTime == null) return;
    final remaining = _signupEndTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      setState(() {
        _signupCountdown = 0;
        _signupEndTime = null;
        _signupTimer?.cancel();
        _signupTimer = null;
      });
    } else {
      setState(() {
        _signupCountdown = remaining;
      });
    }
  }

  void _updateResetCountdown() {
    if (_resetEndTime == null) return;
    final remaining = _resetEndTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      setState(() {
        _resetCountdown = 0;
        _resetEndTime = null;
        _resetTimer?.cancel();
        _resetTimer = null;
      });
    } else {
      setState(() {
        _resetCountdown = remaining;
      });
    }
  }

  void _startSignupCountdown() {
    _signupEndTime = DateTime.now().add(const Duration(seconds: 60));
    setState(() => _signupCountdown = 60);
    _signupTimer?.cancel();
    _signupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateSignupCountdown();
    });
  }

  Future<void> _sendSignupCode() async {
    if (_isSendingCode || _signupCountdown > 0) return;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppToast.show(context, '请输入有效邮箱', isError: true);
      return;
    }
    setState(() => _isSendingCode = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendVerificationCode(email, type: 'signup');
      _startSignupCountdown();
      if (mounted) {
        AppToast.show(context, '验证码已发送，请检查邮箱');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, '发送失败: ${userErrorMessage(e)}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_accounts') ?? [];
    setState(() {
      _savedAccounts = list;
      if (list.isNotEmpty) {
        _emailController.text = list.first;
      }
    });
  }

  Future<void> _saveAccount(String value) async {
    if (value.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_accounts') ?? [];
    if (!list.contains(value)) {
      list.insert(0, value);
      if (list.length > 5) {
        list.removeLast();
      }
      await prefs.setStringList('saved_accounts', list);
    } else {
      list.remove(value);
      list.insert(0, value);
      await prefs.setStringList('saved_accounts', list);
    }
  }

  Future<void> _submit() async {
    // 节流防抖：若正在提交，则直接返回
    if (ref.read(authControllerProvider).isLoading || _isResettingPassword) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final inputVal = _emailController.text.trim();

    if (_isResetPassword) {
      setState(() => _isResettingPassword = true);
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.resetPassword(
          email: inputVal,
          newPassword: _passwordController.text,
          code: _codeController.text.trim(),
        );
        if (mounted) {
          AppToast.show(context, '密码重置成功，请使用新密码登录');
          setState(() {
            _isResetPassword = false;
            _isSignup = false;
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            _nameController.clear();
            _codeController.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(context, '重置失败: ${userErrorMessage(e)}', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isResettingPassword = false);
        }
      }
      return;
    }

    if (_isSignup) {
      await controller.signup(
        email: inputVal,
        password: _passwordController.text,
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
      );
    } else {
      await controller.login(
        email: inputVal,
        password: _passwordController.text,
      );
    }

    final state = ref.read(authControllerProvider);
    if (!mounted) return;

    state.whenOrNull(
      data: (session) {
        if (session != null) {
          _saveAccount(inputVal);
          context.go('/');
        }
      },
      error: (error, _) {
        AppToast.show(context, userErrorMessage(error), isError: true);
      },
    );
  }

  void _startResetCountdown() {
    _resetEndTime = DateTime.now().add(const Duration(seconds: 60));
    setState(() => _resetCountdown = 60);
    _resetTimer?.cancel();
    _resetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateResetCountdown();
    });
  }

  Future<void> _sendResetCode() async {
    if (_isSendingResetCode || _resetCountdown > 0) return;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppToast.show(context, '请输入有效邮箱', isError: true);
      return;
    }
    setState(() => _isSendingResetCode = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendVerificationCode(email, type: 'reset');
      _startResetCountdown();
      if (mounted) {
        AppToast.show(context, '验证码已发送，请检查邮箱');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, '发送失败: ${userErrorMessage(e)}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingResetCode = false);
      }
    }
  }
}
