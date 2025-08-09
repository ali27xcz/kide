# 🛠️ دليل التطوير - Development Guide

## 🚀 **بدء التطوير**

### **📋 المتطلبات الأساسية**

```bash
# Flutter SDK (3.0+)
flutter --version

# Android Studio أو VS Code
# Git
git --version

# Firebase CLI (اختياري)
npm install -g firebase-tools
```

### **⚙️ إعداد البيئة**

```bash
# 1. استنساخ المشروع
git clone https://github.com/[username]/little_scholars_app.git
cd little_scholars_app

# 2. تثبيت Dependencies
flutter pub get

# 3. إعداد المحاكي أو الجهاز
flutter devices

# 4. تشغيل التطبيق
flutter run
```

---

## 🏗️ **هيكل المشروع المفصل**

```
little_scholars_app/
├── 📁 android/                 # Android-specific files
│   ├── app/
│   │   ├── build.gradle       # Android build configuration
│   │   ├── google-services.json # Firebase config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/        # Kotlin code
├── 📁 assets/                 # Static assets (images, sounds)
│   ├── images/               # App images and icons
│   ├── sounds/               # Sound effects and music
│   └── fonts/                # Custom fonts
├── 📁 ios/                   # iOS-specific files (future)
├── 📁 lib/                   # Main Dart code
│   ├── 📄 main.dart          # App entry point
│   ├── 📁 models/            # Data models
│   │   ├── achievement.dart
│   │   ├── child_profile.dart
│   │   ├── game_progress.dart
│   │   └── parent_profile.dart
│   ├── 📁 providers/         # State management
│   │   ├── auth_provider.dart
│   │   └── language_provider.dart
│   ├── 📁 screens/           # UI screens
│   │   ├── auth/            # Authentication screens
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── games/           # Game screens
│   │   │   ├── counting_game_screen.dart
│   │   │   ├── alphabet_game_screen.dart
│   │   │   ├── shapes_game_screen.dart
│   │   │   ├── colors_game_screen.dart
│   │   │   ├── puzzle_game_screen.dart
│   │   │   └── memory_game_screen.dart
│   │   ├── games_menu_screen.dart
│   │   ├── home_screen.dart
│   │   ├── profile_screen.dart
│   │   └── settings_screen.dart
│   ├── 📁 services/          # Business logic services
│   │   ├── audio_service.dart
│   │   ├── firebase_auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── local_storage.dart
│   │   └── progress_tracker.dart
│   ├── 📁 widgets/           # Reusable widgets
│   │   ├── animated_character.dart
│   │   ├── game_button.dart
│   │   ├── language_switch_button.dart
│   │   └── progress_indicator.dart
│   ├── 📁 utils/             # Utilities and constants
│   │   ├── colors.dart       # App color palette
│   │   ├── constants.dart    # App constants
│   │   └── validators.dart   # Input validators
│   └── 📁 l10n/              # Localization files
│       ├── app_localizations.dart
│       ├── app_localizations_ar.dart
│       ├── app_localizations_en.dart
│       ├── intl_ar.arb      # Arabic translations
│       └── intl_en.arb      # English translations
├── 📁 test/                  # Test files
├── 📁 release/               # Release builds
│   ├── LittleScholars-v1.0.0.apk
│   ├── LittleScholars-v1.0.0-arm64.apk
│   └── release-info.md
├── 📄 pubspec.yaml          # Project configuration
├── 📄 .gitignore           # Git ignore rules
├── 📄 README.md            # Project documentation
├── 📄 CONTRIBUTING.md      # Contribution guide
├── 📄 LICENSE              # License file
└── 📄 GITHUB_SETUP.md      # GitHub setup guide
```

---

## 🎮 **بنية الألعاب**

### **🎯 نمط Game Screen العام**

```dart
class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> 
    with TickerProviderStateMixin {
  
  // Game state variables
  int _currentLevel = 1;
  int _score = 0;
  bool _isGameActive = false;
  
  // Animation controllers
  late AnimationController _animationController;
  
  // Services
  AudioService? _audioService;
  ProgressTracker? _progressTracker;
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }
  
  void _initializeGame() {
    // Initialize game logic
  }
  
  void _generateRound() {
    // Generate new game round
  }
  
  void _handleAnswer(dynamic answer) {
    // Process player answer
  }
  
  void _updateScore() {
    // Update score and progress
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Game UI
    );
  }
}
```

### **🔄 إضافة لعبة جديدة**

1. **إنشاء ملف اللعبة**:
```bash
touch lib/screens/games/new_game_screen.dart
```

2. **إضافة في constants.dart**:
```dart
static const String newGame = 'new_game';
```

3. **إضافة في games_menu_screen.dart**:
```dart
GameInfo(
  id: AppConstants.newGame,
  title: 'لعبة جديدة',
  subtitle: 'وصف اللعبة',
  // ... باقي الخصائص
),
```

4. **إضافة Navigation**:
```dart
case AppConstants.newGame:
  gameScreen = const NewGameScreen();
  break;
```

---

## 🔧 **الخدمات الأساسية**

### **🔐 AuthProvider**
```dart
// التحقق من تسجيل الدخول
bool get isLoggedIn => _currentUser != null;

// تسجيل دخول
Future<bool> signIn(String email, String password);

// إنشاء حساب
Future<bool> signUp(String email, String password, String name);

// تسجيل خروج
Future<void> signOut();
```

### **🌐 LanguageProvider**
```dart
// تغيير اللغة
void changeLanguage(String languageCode);

// الحصول على اللغة الحالية
Locale get currentLocale;

// التحقق من التهيئة
bool get isInitialized;
```

### **📊 ProgressTracker**
```dart
// تسجيل تقدم اللعبة
Future<void> recordGameProgress({
  required String gameType,
  required int level,
  required int score,
  required int maxScore,
  required int timeSpentSeconds,
});

// الحصول على الإحصائيات
Future<Map<String, dynamic>> getPlayerStats(String childId);
```

---

## 🎨 **النظام اللوني**

### **🌈 AppColors**
```dart
// الألوان الأساسية
static const Color primary = Color(0xFF4285F4);
static const Color secondary = Color(0xFF34A853);
static const Color accent = Color(0xFFFBBC05);
static const Color warning = Color(0xFFEA4335);

// ألوان الخلفية
static const Color background = Color(0xFFF8F9FA);
static const Color surface = Color(0xFFFFFFFF);

// ألوان النص
static const Color textPrimary = Color(0xFF202124);
static const Color textSecondary = Color(0xFF5F6368);

// ألوان الألعاب
static const Color gameSuccess = Color(0xFF4CAF50);
static const Color gameError = Color(0xFFE57373);
static const Color funPink = Color(0xFFFF85A1);
static const Color funCyan = Color(0xFF85E3FF);
```

---

## 🧪 **الاختبار**

### **🔬 Unit Tests**
```bash
# تشغيل جميع الاختبارات
flutter test

# اختبار ملف محدد
flutter test test/services/progress_tracker_test.dart

# تشغيل مع تغطية الكود
flutter test --coverage
```

### **📱 Integration Tests**
```bash
# اختبار على الجهاز
flutter test integration_test/app_test.dart

# اختبار على المحاكي
flutter test integration_test/ -d emulator-5554
```

### **🎮 اختبار الألعاب**
```dart
// مثال على اختبار لعبة العد
testWidgets('Counting game should generate correct options', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('لعبة العد'));
  await tester.pumpAndSettle();
  
  // التحقق من وجود خيارات صحيحة
  expect(find.byType(CountingGameScreen), findsOneWidget);
});
```

---

## 🚀 **البناء والنشر**

### **🏗️ أوامر البناء**

```bash
# Debug build
flutter build apk --debug

# Release build (عام)
flutter build apk --release

# Release build (محسّن)
flutter build apk --release --split-per-abi

# iOS build (مستقبلي)
flutter build ios --release
```

### **📦 إعداد Release**

```bash
# تنظيف المشروع
flutter clean

# جلب Dependencies
flutter pub get

# تحليل الكود
flutter analyze

# تنسيق الكود
dart format .

# بناء Release
flutter build apk --release --split-per-abi
```

---

## 🔄 **Git Workflow**

### **🌿 Branch Strategy**
```bash
# Main branch للإصدارات المستقرة
main

# Development branch للتطوير
develop

# Feature branches للميزات الجديدة
feature/new-game-addition
feature/ui-improvements

# Hotfix branches للإصلاحات العاجلة
hotfix/critical-bug-fix
```

### **📝 Commit Messages**
```bash
# إضافة ميزة جديدة
feat: add memory game with card matching

# إصلاح خطأ
fix: resolve counting game duplicate options

# تحسين الأداء
perf: optimize image loading in games

# تحديث التوثيق
docs: update README with new installation steps

# إعادة هيكلة الكود
refactor: reorganize game screen components
```

---

## 📚 **مصادر إضافية**

### **📖 التوثيق الرسمي**
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)

### **🎯 أدوات مفيدة**
- **Flutter Inspector**: لتحليل واجهة المستخدم
- **Dart DevTools**: لتحليل الأداء  
- **Firebase Console**: لإدارة البيانات
- **Flutter Intl**: لإدارة الترجمات

### **🤝 المجتمع**
- [Flutter Community](https://flutter.dev/community)
- [Firebase Community](https://firebase.blog/posts/2021/02/firebase-community)
- [GitHub Discussions](https://github.com/[username]/little_scholars_app/discussions)

---

<div align="center">
  <p>💻 Happy Coding! كود سعيد!</p>
</div>
