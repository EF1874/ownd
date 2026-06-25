// ignore_for_file: invalid_use_of_protected_member

part of '../login_screen.dart';

extension _LoginContent on _LoginScreenState {
  Widget _buildLoginScaffold(BuildContext context) {
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
                      _isResetPassword
                          ? '重置密码'
                          : (_isSignup ? '创建物记账号' : '登录物记'),
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
                        if (_isSignup || _isResetPassword) {
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
                                color: isDark
                                    ? const Color(0xFF1E1E24)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2E2E38)
                                      : const Color(0xFFE4E4E7),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.4 : 0.1,
                                    ),
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
                                  color: isDark
                                      ? const Color(0xFF2E2E38)
                                      : const Color(0xFFF4F4F5),
                                ),
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    borderRadius: BorderRadius.vertical(
                                      top: index == 0
                                          ? const Radius.circular(12)
                                          : Radius.zero,
                                      bottom: index == options.length - 1
                                          ? const Radius.circular(12)
                                          : Radius.zero,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.history,
                                            size: 16,
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: isDark
                                                        ? Colors.white70
                                                        : Colors.black87,
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
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return TextFormField(
                              key: ValueKey(
                                _isResetPassword
                                    ? 'reset_email_field'
                                    : (_isSignup
                                          ? 'signup_email_field'
                                          : 'login_credential_field'),
                              ),
                              controller: textEditingController,
                              focusNode: focusNode,
                              onFieldSubmitted: (value) => onFieldSubmitted(),
                              onChanged: (value) {
                                setState(() {});
                              },
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: (_isSignup || _isResetPassword)
                                    ? '邮箱'
                                    : '用户名或邮箱',
                                suffixIcon:
                                    textEditingController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            textEditingController.clear();
                                          });
                                        },
                                      )
                                    : (_savedAccounts.isNotEmpty &&
                                              !_isSignup &&
                                              !_isResetPassword
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.arrow_drop_down,
                                              ),
                                              onPressed: () {
                                                if (focusNode.hasFocus) {
                                                  focusNode.unfocus();
                                                  Future.delayed(
                                                    const Duration(
                                                      milliseconds: 50,
                                                    ),
                                                    () => focusNode
                                                        .requestFocus(),
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
                                  return (_isSignup || _isResetPassword)
                                      ? '请输入邮箱'
                                      : '请输入用户名或邮箱';
                                }
                                if ((_isSignup || _isResetPassword) &&
                                    !value.contains('@')) {
                                  return '请输入有效邮箱';
                                }
                                return null;
                              },
                            );
                          },
                      textEditingController: _emailController,
                      focusNode: _emailFocusNode,
                    ),
                    if (_isSignup || _isResetPassword) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(
                                _isResetPassword
                                    ? 'reset_code_field'
                                    : 'signup_code_field',
                              ),
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
                                if (!_isSignup && !_isResetPassword) {
                                  return null;
                                }
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
                              onPressed: _isResetPassword
                                  ? ((_resetCountdown > 0 ||
                                            _isSendingResetCode)
                                        ? null
                                        : _sendResetCode)
                                  : ((_signupCountdown > 0 || _isSendingCode)
                                        ? null
                                        : _sendSignupCode),
                              child:
                                  (_isResetPassword
                                      ? _isSendingResetCode
                                      : _isSendingCode)
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isResetPassword
                                          ? (_resetCountdown > 0
                                                ? '${_resetCountdown}s'
                                                : '获取验证码')
                                          : (_signupCountdown > 0
                                                ? '${_signupCountdown}s'
                                                : '获取验证码'),
                                    ),
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
                      keyboardType: TextInputType.visiblePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: _isResetPassword
                            ? '新密码'
                            : (_isSignup ? '设置密码' : '密码'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
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
                    if (_isSignup || _isResetPassword) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: ValueKey(
                          _isResetPassword
                              ? 'reset_confirm_password_field'
                              : 'signup_confirm_password_field',
                        ),
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        keyboardType: TextInputType.visiblePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: _isResetPassword ? '确认新密码' : '确认密码',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (!_isSignup && !_isResetPassword) return null;
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
                    if (!_isSignup && !_isResetPassword)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isResetPassword = true;
                              _isSignup = false;
                              _emailController.clear();
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                              _nameController.clear();
                              _codeController.clear();
                            });
                          },
                          child: const Text('忘记密码？'),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: (isLoading || _isResettingPassword)
                          ? null
                          : _submit,
                      child: (isLoading || _isResettingPassword)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isResetPassword
                                  ? '重置密码'
                                  : (_isSignup ? '注册并登录' : '登录'),
                            ),
                    ),
                    if (_isResetPassword)
                      TextButton(
                        onPressed: (isLoading || _isResettingPassword)
                            ? null
                            : () {
                                setState(() {
                                  _isResetPassword = false;
                                  _isSignup = false;
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  _nameController.clear();
                                  _codeController.clear();
                                });
                              },
                        child: const Text('返回登录'),
                      )
                    else
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
