import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/language_switch_button.dart';
import '../../l10n/app_localizations.dart';
import '../home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    return RawAutocomplete<String>(
      textEditingController: _emailController,
      focusNode: _emailFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text;
        final atIndex = text.indexOf('@');
        if (atIndex == -1) {
          return const Iterable<String>.empty();
        }
        final localPart = text.substring(0, atIndex);
        final domainPart = text.substring(atIndex + 1).toLowerCase();
        if (localPart.isEmpty) {
          return const Iterable<String>.empty();
        }
        final matches = _emailDomains.where((d) => d.startsWith(domainPart));
        return matches.map((d) => '$localPart@$d');
      },
      onSelected: (String selection) {
        _emailController.value = TextEditingValue(
          text: selection,
          selection: TextSelection.collapsed(offset: selection.length),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.emailLabel ?? 'البريد الإلكتروني',
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
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
      },
      optionsViewBuilder: (context, onSelected, options) {
        final items = options.toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, minWidth: 280),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final option = items[index];
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: items.length,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.termsRequired ?? 'يجب الموافقة على الشروط والأحكام'),
          backgroundColor: AppColors.incorrect,
        ),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );
    
    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.success ?? 'تم إنشاء الحساب بنجاح'),
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
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? AppLocalizations.of(context)?.error ?? 'حدث خطأ في إنشاء الحساب'),
          backgroundColor: AppColors.incorrect,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.createNewAccount ?? 'إنشاء حساب جديد'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language Switch Button in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: const LanguageSwitchButton(showText: false, size: 20),
          ),
        ],
      ),
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
                      
                      // Header
                      _buildHeader(),
                      
                      const SizedBox(height: 40),
                      
                      // Sign Up Form
                      _buildSignUpForm(),
                      
                      const SizedBox(height: 24),
                      
                      // Terms and Conditions
                      _buildTermsAndConditions(),
                      
                      const SizedBox(height: 32),
                      
                      // Sign Up Button
                      _buildSignUpButton(),
                      
                      const SizedBox(height: 24),
                      
                      // Login Link
                      _buildLoginLink(),
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.school,
            size: 50,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Title
        Text(
          AppLocalizations.of(context)?.joinTitle ?? 'انضم إلى كيدي',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          AppLocalizations.of(context)?.joinSubtitle ?? 'أنشئ حسابك لمتابعة تقدم أطفالك التعليمي',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      children: [
        // Name Field
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.fullNameLabel ?? 'الاسم الكامل',
            prefixIcon: const Icon(Icons.person_outlined),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)?.nameRequired ?? 'يرجى إدخال الاسم الكامل';
            }
            if (value.length < 3) {
              return AppLocalizations.of(context)?.nameTooShort ?? 'الاسم يجب أن يكون 3 أحرف على الأقل';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Email Field with domain autocomplete
        _buildEmailFieldWithAutocomplete(),
        
        const SizedBox(height: 16),
        
        // Phone Field (Optional)
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.phoneLabel ?? 'رقم الهاتف (اختياري)',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.passwordLabel ?? 'كلمة المرور',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: const OutlineInputBorder(),
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
        
        const SizedBox(height: 16),
        
        // Confirm Password Field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.confirmPasswordLabel ?? 'تأكيد كلمة المرور',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)?.passwordRequired ?? 'يرجى تأكيد كلمة المرور';
            }
            if (value != _passwordController.text) {
              return AppLocalizations.of(context)?.passwordMismatch ?? 'كلمة المرور غير متطابقة';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(text: AppLocalizations.of(context)?.agreeToTerms ?? 'أوافق على الشروط والأحكام وسياسة الخصوصية'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return ElevatedButton(
          onPressed: authProvider.isLoading ? null : _handleSignUp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                  AppLocalizations.of(context)?.signupButton ?? 'إنشاء الحساب',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(AppLocalizations.of(context)?.hasAccount ?? 'لديك حساب بالفعل؟'),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)?.backToLogin ?? 'تسجيل الدخول'),
        ),
      ],
    );
  }
}
