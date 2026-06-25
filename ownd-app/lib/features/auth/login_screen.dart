import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_controller.dart';
import '../../shared/widgets/app_toast.dart';
import '../../core/network/error_messages.dart';

part 'widgets/login_actions.dart';
part 'widgets/login_content.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
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
  bool _isResetPassword = false;
  bool _isResettingPassword = false;
  bool _isSendingResetCode = false;

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

  @override
  Widget build(BuildContext context) => _buildLoginScaffold(context);
}
