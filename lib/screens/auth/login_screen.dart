import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/language_switch_button.dart';
import '../../l10n/app_localizations.dart';
import '../../services/local_storage.dart';
import '../home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final List<String> _emailDomains = const [
    'kimeel.com',
    'icloud.com',
    'gmail.com',
    'outlook.com',
    'yahoo.com',
    'hotmail.com',
  ];
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  // Simple form without suggestions
  // Rive (Teddy) state
  Artboard? _riveArtboard;
  StateMachineController? _riveController;
  SMIBool? _isCheckingBool;
  SMINumber? _isCheckingNum;
  SMIBool? _isHandsUp;
  SMITrigger? _successTrig;
  SMITrigger? _failTrig;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedCredentials();
    _loadRiveFile();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
  }

  // --- Rive helpers ---
  void _loadRiveFile() async {}

  void _onRiveInit(Artboard artboard) {
    print('==> _onRiveInit called');
    final controller = StateMachineController.fromArtboard(artboard, 'Login Machine');
    if (controller != null) {
      artboard.addController(controller);
      _riveController = controller;
      for (final input in controller.inputs) {
        print('Rive input: name = \'${input.name}\', type = \'${input.runtimeType}\'');
      }
      _isHandsUp = controller.findSMI('isHandsUp') as SMIBool?;
      _isCheckingBool = controller.findSMI('isChecking') as SMIBool?;
      _isCheckingNum = controller.findSMI('numLook') as SMINumber?;
      _successTrig = controller.findSMI('trigSuccess') as SMITrigger?;
      _failTrig = controller.findSMI('trigFail') as SMITrigger?;
      if (_isHandsUp == null) print('تحذير: لم يتم العثور على متغير isHandsUp في State Machine!');
      // Set initial state for Rive inputs
      _isCheckingBool?.value = false;
      _isHandsUp?.value = false;
      _isCheckingNum?.value = 0;
    } else {
      print('تحذير: لم يتم العثور على State Machine باسم Login Machine!');
      try {
        artboard.addController(SimpleAnimation('idle'));
      } catch (_) {}
    }
    setState(() => _riveArtboard = artboard);
  }

  void _onEmailChanged(String value) {
    // تفعيل isChecking عند وجود نص في الحقل
    _isCheckingBool?.value = _emailFocusNode.hasFocus && value.isNotEmpty;
    // تحريك العينين حسب طول النص (أو يمكنك استخدام منطق آخر)
    if (_isCheckingNum != null) {
      // اجعل العينين تتحرك من 0 (يسار) إلى 100 (يمين) حسب طول النص
      final mapped = (value.length * 12).clamp(0, 100).toDouble();
      _isCheckingNum!.value = mapped;
    }
  }

  void _onEmailFocusChange() {
    final hasFocus = _emailFocusNode.hasFocus;
    // تفعيل isChecking عند التركيز على الحقل
    if (_isCheckingBool != null) {
      _isCheckingBool!.value = hasFocus && _emailController.text.isNotEmpty;
    }
    // عند فقدان التركيز، إعادة العينين للوضع الطبيعي
    if (!hasFocus && _isCheckingNum != null) {
      _isCheckingNum!.value = 0;
    }
  }

  void _onPasswordFocusChange() {
    final hasFocus = _passwordFocusNode.hasFocus;
    // رفع اليدين عند التركيز على كلمة المرور
    if (_isHandsUp != null) {
      _isHandsUp!.value = hasFocus;
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final rememberMeEnabled = await storage.hasRememberMeEnabled();
      
      if (rememberMeEnabled) {
        final credentials = await storage.getSavedLoginCredentials();
        if (credentials != null) {
          setState(() {
            _emailController.text = credentials['email'] ?? '';
            _passwordController.text = credentials['password'] ?? '';
            _rememberMe = true;
          });
          print('Saved credentials loaded');
        }
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _passwordFocusNode.dispose();
    _riveController?.dispose();
    super.dispose();
  }



  void _showEmailDomainSuggestions() async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final currentText = _emailController.text.trim();
        final atIndex = currentText.indexOf('@');
        final localPart = atIndex >= 0 ? currentText.substring(0, atIndex) : currentText;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: _emailDomains.map((domain) {
              final suggestion = localPart.isNotEmpty ? '$localPart@$domain' : '@$domain';
              return ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(suggestion),
                onTap: () {
                  _emailController.text = suggestion;
                  if (localPart.isEmpty) {
                    _emailController.selection = const TextSelection.collapsed(offset: 0);
                  } else {
                    _emailController.selection = TextSelection.collapsed(offset: _emailController.text.length);
                  }
                  Navigator.of(ctx).pop();
                  _emailFocusNode.requestFocus();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      onChanged: _onEmailChanged,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)?.emailLabel ?? 'البريد الإلكتروني',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: Colors.grey.shade600,
        ),
        suffixIcon: IconButton(
          tooltip: '@',
          icon: Icon(
            Icons.alternate_email,
            color: Colors.grey.shade600,
          ),
          onPressed: _showEmailDomainSuggestions,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)?.emailRequired ?? 'يرجى إدخال البريد الإلكتروني';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return AppLocalizations.of(context)?.emailInvalid ?? 'يرجى إدخال بريد إلكتروني صحيح';
        }
        return null;
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    print('Login screen: Starting login process');
    
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    
    print('Login screen: Login result - success: $success, error: ${authProvider.errorMessage}');
    print('Login screen: Mounted: $mounted');
    
    if (success && mounted) {
      _successTrig?.fire(); // تفعيل حركة النجاح
      // Handle Remember Me functionality
      try {
        final storage = await LocalStorageService.getInstance();
        await storage.setRememberMeEnabled(_rememberMe);
        
        if (_rememberMe) {
          await storage.saveLoginCredentials(
            _emailController.text.trim(),
            _passwordController.text,
          );
          print('Login credentials saved for remember me');
        } else {
          await storage.clearSavedLoginCredentials();
          print('Login credentials cleared');
        }
      } catch (e) {
        print('Error handling remember me: $e');
      }
      
      print('Login screen: Showing success message');
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.success ?? 'تم تسجيل الدخول بنجاح'),
          backgroundColor: AppColors.correct,
        ),
      );
      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else if (mounted) {
      _failTrig?.fire(); // تفعيل حركة الفشل
      // If auth state is already logged in (race condition), treat as success
      if (Provider.of<AuthProvider>(context, listen: false).isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
        return;
      }
      print('Login screen: Showing error message: ${authProvider.errorMessage}');
      print('Login screen: Error message is null: ${authProvider.errorMessage == null}');
      // Show clear, professional error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة'),
          backgroundColor: AppColors.incorrect,
        ),
      );
    } else {
      print('Login screen: Not mounted, cannot show message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر تغيير اللغة في الأعلى يمين
                      Padding(
  padding: const EdgeInsets.only(top: 8.0, right: 24.0, left: 24.0, bottom: 0),
  child: Align(
    alignment: Alignment.centerRight,
    child: LanguageSwitchButton(),
  ),
),
                      // رفع الدب للأعلى قليلاً
                      _buildHeader(),
                      const SizedBox(height: 24),
                      // نموذج الدخول بعرض ثابت مناسب
                      Container(
                        width: 350, // أو استخدم min(350, MediaQuery.of(context).size.width * 0.95)
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLoginForm(),
                            const SizedBox(height: 20),
                            _buildLoginButton(),
                            const SizedBox(height: 16),
                            // نسيت كلمة المرور + إنشاء حساب جديد في نفس السطر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)?.forgotPassword ?? 'نسيت كلمة المرور؟',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('|', style: TextStyle(color: Colors.grey.shade400)),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const SignUpScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)?.createAccount ?? 'إنشاء حساب جديد',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(
          width: 320,
          height: 300,
          child: RiveAnimation.asset(
            'assets/rive/teddy_login_screen.riv',
            fit: BoxFit.contain,
            onInit: _onRiveInit,
          ),
        ),
        const SizedBox(height: 12),
        // العنوان
        Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context);
            final locale = Localizations.localeOf(context);
            print('Login screen - AppLocalizations:  ̷localizations?.welcomeTitle}, Locale: $locale');
            return Text(
              localizations?.welcomeTitle ?? 'مرحباً بك في كيدي',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        const SizedBox(height: 4),
        // الوصف
        Text(
          AppLocalizations.of(context)?.welcomeSubtitle ?? 'سجل دخولك لمتابعة تقدم أطفالك',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email Field
        _buildEmailField(),
        const SizedBox(height: 16),
        // Password Field
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.passwordLabel ?? 'كلمة المرور',
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: Colors.grey.shade600,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            print('onChanged password, _isHandsUp: \\${_isHandsUp}');
            if (_isHandsUp != null) {
              _isHandsUp!.value = value.isNotEmpty || _passwordFocusNode.hasFocus;
            }
          },
          onFieldSubmitted: (_) {
            print('onFieldSubmitted password, _isHandsUp: \\${_isHandsUp}');
            if (_isHandsUp != null) {
              _isHandsUp!.value = false;
            }
          },
          onEditingComplete: () {
            print('onEditingComplete password, _isHandsUp: \\${_isHandsUp}');
            if (_isHandsUp != null) {
              _isHandsUp!.value = false;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)?.passwordRequired ?? 'يرجى إدخال كلمة المرور';
            }
            if (value.length < 6) {
              return AppLocalizations.of(context)?.passwordTooShort ?? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Remember Me Checkbox
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              activeColor: AppColors.primary,
            ),
            Text(
              AppLocalizations.of(context)?.rememberMe ?? 'تذكرني',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return ElevatedButton(
          onPressed: authProvider.isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: authProvider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  AppLocalizations.of(context)?.loginButton ?? 'تسجيل الدخول',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        );
      },
    );
  }
}
