import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/language_switch_button.dart';
import '../../l10n/app_localizations.dart';
import '../home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

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
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  // New email suggestion system
  String _localPart = '';
  String _suggestedDomain = 'gmail.com';
  bool _showDomainSuggestion = true;
  bool _isDomainDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupEmailController();
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

  void _setupEmailController() {
    _emailController.addListener(_onEmailChanged);
    _emailFocusNode.addListener(() {
      setState(() {}); // لتحديث لون الحدود
    });
  }

  void _onEmailChanged() {
    final text = _emailController.text;
    final atIndex = text.indexOf('@');
    
    if (atIndex == -1) {
      setState(() {
        _localPart = text;
        _showDomainSuggestion = text.isNotEmpty;
      });
    } else {
      setState(() {
        _localPart = text.substring(0, atIndex);
        _showDomainSuggestion = false;
      });
    }
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isDomainDropdownOpen = false;
    });
  }

  void _showDropdown() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildDropdownOverlay(),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDomainDropdownOpen = true;
    });
  }

  Widget _buildDropdownOverlay() {
    return GestureDetector(
      onTap: _hideDropdown,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 60),
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(right: 50),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.alternate_email,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'اختر الاستضافة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...(_emailDomains.map((domain) => _buildDomainOption(domain))),
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: GestureDetector(
                        onTap: () {
                          _hideDropdown();
                          // إزالة الاقتراح للسماح بإدخال استضافة مخصصة
                          setState(() {
                            _showDomainSuggestion = false;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'إدخال مخصص',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainOption(String domain) {
    return GestureDetector(
      onTap: () => _selectDomain(domain),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _suggestedDomain == domain 
              ? AppColors.primary.withOpacity(0.1) 
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              _suggestedDomain == domain ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: _suggestedDomain == domain ? AppColors.primary : Colors.grey.shade400,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              domain,
              style: TextStyle(
                fontSize: 14,
                fontWeight: _suggestedDomain == domain ? FontWeight.w600 : FontWeight.normal,
                color: _suggestedDomain == domain ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDomain(String domain) {
    setState(() {
      _suggestedDomain = domain;
      _emailController.text = '$_localPart@$domain';
      _emailController.selection = TextSelection.collapsed(offset: _emailController.text.length);
    });
    _hideDropdown();
  }

  @override
  void dispose() {
    _hideDropdown();
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static const List<String> _emailDomains = <String>[
    'gmail.com',
    'icloud.com',
    'outlook.com',
    'hotmail.com',
    'yahoo.com',
    'live.com',
    'proton.me',
    'yandex.com',
  ];

  Widget _buildEmailFieldWithAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _emailFocusNode.hasFocus 
                    ? AppColors.primary 
                    : Colors.grey.shade300,
                width: 2,
              ),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Email input field
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.emailLabel ?? 'البريد الإلكتروني',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          Icons.email_outlined,
                          color: _emailFocusNode.hasFocus 
                              ? AppColors.primary 
                              : Colors.grey.shade600,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
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
                  ),
                ),
                
                // Domain suggestion area
                if (_showDomainSuggestion && _localPart.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // @ symbol
                        Text(
                          '@',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        // Domain suggestion with dropdown
                        GestureDetector(
                          onTap: _showDropdown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _suggestedDomain,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isDomainDropdownOpen 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Accept suggestion button
                        GestureDetector(
                          onTap: () {
                            _emailController.text = '$_localPart@$_suggestedDomain';
                            _emailController.selection = TextSelection.collapsed(
                              offset: _emailController.text.length,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Language Switch Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: const LanguageSwitchButton(),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Logo and Title
                      _buildHeader(),
                      
                      const SizedBox(height: 60),
                      
                      // Login Form
                      _buildLoginForm(),
                      
                      const SizedBox(height: 32),
                      
                      // Login Button
                      _buildLoginButton(),
                      
                      const SizedBox(height: 40),
                      
                      // Forgot Password
                      _buildForgotPassword(),
                      
                      const SizedBox(height: 40),
                      
                      // Sign Up Link
                      _buildSignUpLink(),
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
        // App Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.school,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context);
            final locale = Localizations.localeOf(context);
            print('Login screen - AppLocalizations: ${localizations?.welcomeTitle}, Locale: $locale');
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
        
        const SizedBox(height: 8),
        
        // Subtitle
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
        // Email Field with domain autocomplete
        _buildEmailFieldWithAutocomplete(),
        
        const SizedBox(height: 16),
        
        // Password Field with modern design
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.passwordLabel ?? 'كلمة المرور',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.lock_outlined,
                  color: Colors.grey.shade600,
                ),
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
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              AppLocalizations.of(context)?.rememberMe ?? 'تذكرني',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)?.loginButton ?? 'تسجيل الدخول',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ForgotPasswordScreen(),
          ),
        );
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        AppLocalizations.of(context)?.forgotPassword ?? 'نسيت كلمة المرور؟',
        style: TextStyle(
          fontSize: 16,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)?.noAccount ?? 'ليس لديك حساب؟',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
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
    );
  }
}

