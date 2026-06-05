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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _isSignup = false;
  List<String> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final inputVal = _emailController.text.trim();
    if (_isSignup) {
      await controller.signup(
        email: inputVal,
        password: _passwordController.text,
        name: _nameController.text.trim(),
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
    final resetNameController = TextEditingController();
    final resetPasswordController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();
    bool resetting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('重置密码'),
              content: Form(
                key: resetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: '注册邮箱'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return '请输入邮箱';
                        if (!value.contains('@')) return '请输入有效邮箱';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: resetNameController,
                      decoration: const InputDecoration(labelText: '用户名'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return '请输入用户名';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: resetPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '新密码'),
                      validator: (value) {
                        if (value == null || value.length < 6) return '密码至少 6 位';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: resetting ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: resetting
                      ? null
                      : () async {
                          if (!resetFormKey.currentState!.validate()) return;
                          setDialogState(() => resetting = true);
                          try {
                            final authRepo = ref.read(authRepositoryProvider);
                            await authRepo.resetPassword(
                              email: resetEmailController.text.trim(),
                              name: resetNameController.text.trim(),
                              newPassword: resetPasswordController.text,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              AppToast.show(context, '密码重置成功，请使用新密码登录');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => resetting = false);
                              AppToast.show(context, '重置失败: ${e.toString()}', isError: true);
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
    );
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
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: '用户名'),
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
                      fieldViewBuilder: (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onFieldSubmitted: (value) => onFieldSubmitted(),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: _isSignup ? '邮箱' : '用户名或邮箱',
                            suffixIcon: _savedAccounts.isNotEmpty && !_isSignup
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
                                : null,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '密码'),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return '密码至少 6 位';
                        }
                        return null;
                      },
                    ),
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
                          : () => setState(() => _isSignup = !_isSignup),
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
