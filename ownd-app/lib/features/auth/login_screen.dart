import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_controller.dart';
import '../../shared/widgets/app_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _isSignup = false;
  List<String> _savedAccounts = [];
  
  // 注册验证码倒计时相关
  int _signupCountdown = 0;
  DateTime? _signupEndTime;
  Timer? _signupTimer;
  bool _isSendingCode = false;

  // 重置密码验证码倒计时相关
  int _resetCountdown = 0;
  DateTime? _resetEndTime;
  Timer? _resetTimer;
  StateSetter? _resetDialogStateSetter;

  // 密码显示隐藏控制
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedAccounts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _emailFocusNode.dispose();
    _signupTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateSignupCountdown();
      _updateResetCountdown();
    }
  }

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
      _resetCountdown = 0;
      _resetEndTime = null;
      _resetTimer?.cancel();
      _resetTimer = null;
    } else {
      _resetCountdown = remaining;
    }
    if (_resetDialogStateSetter != null) {
      _resetDialogStateSetter!(() {});
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
      await ref.read(authRepositoryProvider).sendVerificationCode(email, type: 'signup');
      _startSignupCountdown();
      if (mounted) {
        AppToast.show(context, '验证码已发送，请检查邮箱');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, '发送失败: ${e.toString().replaceAll('ApiException: ', '')}', isError: true);
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
    if (ref.read(authControllerProvider).isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final inputVal = _emailController.text.trim();
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
        AppToast.show(context, error.toString(), isError: true);
      },
    );
  }

  void _showResetPasswordDialog() {
    final resetEmailController = TextEditingController();
    final resetPasswordController = TextEditingController();
    final resetConfirmPasswordController = TextEditingController();
    final resetCodeController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();
    bool resetting = false;
    bool isSendingResetCode = false;
    bool obscureResetPassword = true;
    bool obscureResetConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _resetDialogStateSetter = setDialogState;
            return AlertDialog(
              title: const Text('重置密码'),
              content: Form(
                key: resetFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: resetEmailController,
                        onChanged: (value) => setDialogState(() {}),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: '注册邮箱',
                          suffixIcon: resetEmailController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      resetEmailController.clear();
                                    });
                                  },
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return '请输入邮箱';
                          if (!value.contains('@')) return '请输入有效邮箱';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: resetCodeController,
                              onChanged: (value) => setDialogState(() {}),
                              decoration: InputDecoration(
                                labelText: '验证码',
                                suffixIcon: resetCodeController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          setDialogState(() {
                                            resetCodeController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return '请输入验证码';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextButton(
                              onPressed: (_resetCountdown > 0 || isSendingResetCode)
                                  ? null
                                  : () async {
                                      final email = resetEmailController.text.trim();
                                      if (email.isEmpty || !email.contains('@')) {
                                        AppToast.show(context, '请输入有效邮箱', isError: true);
                                        return;
                                      }
                                      setDialogState(() => isSendingResetCode = true);
                                      try {
                                        await ref.read(authRepositoryProvider).sendVerificationCode(email, type: 'reset');
                                        _resetEndTime = DateTime.now().add(const Duration(seconds: 60));
                                        setDialogState(() {
                                          _resetCountdown = 60;
                                        });
                                        _resetTimer?.cancel();
                                        _resetTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                                          if (!context.mounted) {
                                            t.cancel();
                                            return;
                                          }
                                          _updateResetCountdown();
                                        });
                                        if (context.mounted) {
                                          AppToast.show(context, '验证码已发送，请检查邮箱');
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          AppToast.show(context, '发送失败: ${e.toString().replaceAll('ApiException: ', '')}', isError: true);
                                        }
                                      } finally {
                                        if (context.mounted) {
                                          setDialogState(() => isSendingResetCode = false);
                                        }
                                      }
                                    },
                              child: isSendingResetCode
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(_resetCountdown > 0 ? '${_resetCountdown}s' : '获取验证码'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: resetPasswordController,
                        obscureText: obscureResetPassword,
                        onChanged: (value) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: '新密码',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureResetPassword ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureResetPassword = !obscureResetPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) return '密码至少 6 位';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: resetConfirmPasswordController,
                        obscureText: obscureResetConfirmPassword,
                        onChanged: (value) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: '确认新密码',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureResetConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureResetConfirmPassword = !obscureResetConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return '请再次输入密码';
                          if (value != resetPasswordController.text) return '两次输入的密码不一致';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: resetting ? null : () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: resetting
                      ? null
                      : () async {
                          if (resetting) return;
                          if (!resetFormKey.currentState!.validate()) return;
                          setDialogState(() => resetting = true);
                          try {
                            final authRepo = ref.read(authRepositoryProvider);
                            await authRepo.resetPassword(
                              email: resetEmailController.text.trim(),
                              newPassword: resetPasswordController.text,
                              code: resetCodeController.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              AppToast.show(context, '密码重置成功，请使用新密码登录');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => resetting = false);
                              AppToast.show(context, '重置失败: ${e.toString().replaceAll('ApiException: ', '')}', isError: true);
                            }
                          }
                        },
                  child: resetting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _resetTimer?.cancel();
      _resetTimer = null;
      _resetEndTime = null;
      _resetCountdown = 0;
      _resetDialogStateSetter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isSignup ? '创建物记账号' : '登录物记',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    if (_isSignup) ...[
                      TextFormField(
                        key: const ValueKey('signup_username_field'),
                        controller: _nameController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: '用户名',
                          suffixIcon: _nameController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _nameController.clear();
                                    });
                                  },
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (!_isSignup) return null;
                          return (value == null || value.trim().isEmpty)
                              ? '请输入用户名'
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (_isSignup) {
                          return const Iterable<String>.empty();
                        }
                        if (textEditingValue.text.isEmpty) {
                          return _savedAccounts;
                        }
                        return _savedAccounts.where((String option) {
                          return option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          );
                        });
                      },
                      onSelected: (String selection) {
                        _emailController.text = selection;
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        final theme = Theme.of(context);
                        final isDark = theme.brightness == Brightness.dark;

                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 372,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE4E4E7),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFF4F4F5),
                                ),
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    borderRadius: BorderRadius.vertical(
                                      top: index == 0 ? const Radius.circular(12) : Radius.zero,
                                      bottom: index == options.length - 1 ? const Radius.circular(12) : Radius.zero,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.history,
                                            size: 16,
                                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: isDark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      fieldViewBuilder: (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return TextFormField(
                          key: ValueKey(_isSignup ? 'signup_email_field' : 'login_credential_field'),
                          controller: textEditingController,
                          focusNode: focusNode,
                          onFieldSubmitted: (value) => onFieldSubmitted(),
                          onChanged: (value) {
                            setState(() {});
                          },
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: _isSignup ? '邮箱' : '用户名或邮箱',
                            suffixIcon: textEditingController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        textEditingController.clear();
                                      });
                                    },
                                  )
                                : (_savedAccounts.isNotEmpty && !_isSignup
                                    ? IconButton(
                                        icon: const Icon(Icons.arrow_drop_down),
                                        onPressed: () {
                                          if (focusNode.hasFocus) {
                                            focusNode.unfocus();
                                            Future.delayed(
                                              const Duration(milliseconds: 50),
                                              () => focusNode.requestFocus(),
                                            );
                                          } else {
                                            focusNode.requestFocus();
                                          }
                                        },
                                      )
                                    : null),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _isSignup ? '请输入邮箱' : '请输入用户名或邮箱';
                            }
                            if (_isSignup && !value.contains('@')) {
                              return '请输入有效邮箱';
                            }
                            return null;
                          },
                        );
                      },
                      textEditingController: _emailController,
                      focusNode: _emailFocusNode,
                    ),
                    if (_isSignup) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('signup_code_field'),
                              controller: _codeController,
                              onChanged: (value) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: '验证码',
                                suffixIcon: _codeController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _codeController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              validator: (value) {
                                if (!_isSignup) return null;
                                return (value == null || value.trim().isEmpty)
                                    ? '请输入验证码'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: TextButton(
                              onPressed: (_signupCountdown > 0 || _isSendingCode) ? null : _sendSignupCode,
                              child: _isSendingCode
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(_signupCountdown > 0 ? '${_signupCountdown}s' : '获取验证码'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('auth_password_field'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: _isSignup ? '设置密码' : '密码',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return '密码至少 6 位';
                        }
                        return null;
                      },
                    ),
                    if (_isSignup) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('signup_confirm_password_field'),
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: '确认密码',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (!_isSignup) return null;
                          if (value == null || value.isEmpty) {
                            return '请再次输入密码';
                          }
                          if (value != _passwordController.text) {
                            return '两次输入的密码不一致';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (!_isSignup)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showResetPasswordDialog,
                          child: const Text('忘记密码？'),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignup ? '注册并登录' : '登录'),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() {
                                _isSignup = !_isSignup;
                                _emailController.clear();
                                _passwordController.clear();
                                _confirmPasswordController.clear();
                                _nameController.clear();
                                _codeController.clear();
                              });
                            },
                      child: Text(_isSignup ? '已有账号？去登录' : '没有账号？去注册'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
