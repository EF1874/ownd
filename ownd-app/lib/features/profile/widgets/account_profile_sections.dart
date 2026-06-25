// ignore_for_file: invalid_use_of_protected_member

part of '../account_profile_screen.dart';

extension _AccountProfileSections on _AccountProfileScreenState {
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
}
