# علماء صغار - Little Scholars

تطبيق تعليمي تفاعلي مصمم خصيصاً للأطفال من عمر 3-12 سنة لتعلم الرياضيات الأساسية والمهارات المعرفية من خلال الألعاب الممتعة.

## 🌟 المميزات

### 🎮 الألعاب التعليمية
- **لعبة العد**: تعلم العد من 1 إلى 20 مع الأصوات والرسوم المتحركة
- **لعبة الجمع**: عمليات الجمع البسيطة بطريقة تفاعلية
- **لعبة الأشكال**: التعرف على الأشكال الهندسية الأساسية
- **لعبة الألوان**: استكشاف الألوان ومطابقتها
- **لعبة الأنماط**: تطوير التفكير المنطقي من خلال الأنماط

### 👤 الملف الشخصي
- إنشاء ملف شخصي مخصص لكل طفل
- تتبع التقدم والإنجازات
- نظام المستويات والنقاط
- إحصائيات مفصلة للأداء

### 🏆 نظام الإنجازات
- شارات وإنجازات متنوعة
- نظام النجوم لتقييم الأداء
- تحفيز مستمر للتعلم

### 🎵 التجربة التفاعلية
- أصوات وموسيقى تفاعلية
- شخصية متحركة ودودة
- واجهة مستخدم بسيطة ومناسبة للأطفال
- دعم كامل للغة العربية

## 🛠 التقنيات المستخدمة

- **Flutter 3.24.5**: إطار العمل الأساسي
- **Dart**: لغة البرمجة
- **SharedPreferences**: تخزين البيانات المحلية
- **AudioPlayers**: تشغيل الأصوات والموسيقى
- **AnimatedTextKit**: النصوص المتحركة
- **Provider**: إدارة الحالة
- **Lottie**: الرسوم المتحركة

## 📱 متطلبات النظام

### Android
- Android 5.0 (API level 21) أو أحدث
- 100 MB مساحة تخزين فارغة
- 2 GB RAM

### iOS
- iOS 12.0 أو أحدث
- 100 MB مساحة تخزين فارغة
- iPhone 6s أو أحدث

## 🚀 التثبيت والتشغيل

### المتطلبات الأساسية
```bash
# تثبيت Flutter SDK
# تأكد من إضافة Flutter إلى PATH

# التحقق من التثبيت
flutter doctor
```

### تشغيل المشروع
```bash
# استنساخ المشروع
git clone [repository-url]
cd little_scholars_app

# تثبيت التبعيات
flutter pub get

# تشغيل التطبيق
flutter run
```

### البناء للإنتاج
```bash
# بناء APK للأندرويد
flutter build apk --release

# بناء AAB للأندرويد
flutter build appbundle --release

# بناء iOS
flutter build ios --release
```

## 📁 هيكل المشروع

```
lib/
├── main.dart                 # نقطة البداية
├── models/                   # نماذج البيانات
│   ├── child_profile.dart
│   ├── game_progress.dart
│   └── achievement.dart
├── services/                 # الخدمات
│   ├── local_storage.dart
│   ├── audio_service.dart
│   └── progress_tracker.dart
├── screens/                  # الشاشات
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── games_menu_screen.dart
│   └── profile_screen.dart
├── widgets/                  # المكونات المخصصة
│   ├── game_button.dart
│   ├── progress_bar.dart
│   ├── achievement_badge.dart
│   └── animated_character.dart
└── utils/                    # الأدوات المساعدة
    ├── colors.dart
    ├── constants.dart
    └── sounds.dart
```

## 🎨 التصميم والألوان

### نظام الألوان
- **الأساسي**: `#6366F1` (Indigo)
- **الثانوي**: `#EC4899` (Pink)
- **الخلفية**: `#F8FAFC` (Slate 50)
- **السطح**: `#FFFFFF` (White)
- **النص الأساسي**: `#1E293B` (Slate 800)

### الألوان التفاعلية
- **أزرق ممتع**: `#3B82F6`
- **أخضر ممتع**: `#10B981`
- **أصفر ممتع**: `#F59E0B`
- **أحمر ممتع**: `#EF4444`
- **بنفسجي ممتع**: `#8B5CF6`
- **برتقالي ممتع**: `#F97316`

## 🔧 الإعدادات والتخصيص

### إعدادات الصوت
```dart
// في audio_service.dart
static const double defaultVolume = 0.7;
static const bool enableBackgroundMusic = true;
static const bool enableSoundEffects = true;
```

### إعدادات اللعبة
```dart
// في constants.dart
static const int maxLevel = 5;
static const int pointsPerStar = 100;
static const int questionsPerGame = 10;
```

## 🧪 الاختبار

```bash
# تشغيل جميع الاختبارات
flutter test

# تشغيل اختبارات محددة
flutter test test/widget_test.dart

# تشغيل اختبارات التكامل
flutter drive --target=test_driver/app.dart
```

## 📊 الأداء والتحسين

### نصائح للأداء
- استخدام `const` constructors حيثما أمكن
- تحسين الصور والأصوات
- استخدام `ListView.builder` للقوائم الطويلة
- تجنب إعادة البناء غير الضرورية

### مراقبة الأداء
```bash
# تشغيل مع مراقبة الأداء
flutter run --profile

# تحليل حجم التطبيق
flutter build apk --analyze-size
```

## 🔒 الأمان والخصوصية

- لا يتم جمع أي بيانات شخصية
- جميع البيانات محفوظة محلياً على الجهاز
- لا يوجد اتصال بالإنترنت مطلوب للعب
- مناسب للأطفال بدون إعلانات

## 🌍 الدعم متعدد اللغات

حالياً يدعم التطبيق:
- العربية (الأساسية)
- الإنجليزية (احتياطية)

### إضافة لغة جديدة
1. إضافة ملفات الترجمة في `lib/l10n/`
2. تحديث `supportedLocales` في `main.dart`
3. إضافة النصوص المترجمة

## 🤝 المساهمة

نرحب بالمساهمات! يرجى اتباع الخطوات التالية:

1. Fork المشروع
2. إنشاء branch جديد (`git checkout -b feature/amazing-feature`)
3. Commit التغييرات (`git commit -m 'Add amazing feature'`)
4. Push إلى Branch (`git push origin feature/amazing-feature`)
5. فتح Pull Request

### معايير الكود
- اتباع [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- إضافة تعليقات للكود المعقد
- كتابة اختبارات للميزات الجديدة
- التأكد من عدم وجود warnings

## 📝 الترخيص

هذا المشروع مرخص تحت رخصة MIT - راجع ملف [LICENSE](LICENSE) للتفاصيل.

## 📞 الدعم والتواصل

- **البريد الإلكتروني**: support@littlescholars.app
- **الموقع الإلكتروني**: https://littlescholars.app
- **التوثيق**: https://docs.littlescholars.app

## 🎯 الخطط المستقبلية

### الإصدار القادم (v2.0)
- [ ] المزيد من الألعاب التعليمية
- [ ] وضع متعدد اللاعبين
- [ ] تقارير مفصلة للآباء
- [ ] دعم الأجهزة اللوحية
- [ ] المزيد من اللغات

### الميزات المطلوبة
- [ ] لعبة الطرح
- [ ] لعبة الضرب البسيط
- [ ] لعبة الحروف العربية
- [ ] لعبة الكلمات
- [ ] وضع التحدي

## 🏅 الشكر والتقدير

شكر خاص لـ:
- فريق Flutter لإطار العمل الرائع
- مجتمع المطورين العرب
- المعلمين والأطفال الذين ساعدوا في الاختبار

---

**ملاحظة**: هذا التطبيق مصمم بحب للأطفال العرب لتعزيز حبهم للتعلم والاستكشاف. 🌟

## 📸 لقطات الشاشة

### الشاشة الرئيسية
![الشاشة الرئيسية](screenshots/home_screen.png)

### قائمة الألعاب
![قائمة الألعاب](screenshots/games_menu.png)

### الملف الشخصي
![الملف الشخصي](screenshots/profile_screen.png)

### لعبة العد
![لعبة العد](screenshots/counting_game.png)

---

*تم تطوير هذا التطبيق بواسطة فريق علماء صغار - جميع الحقوق محفوظة © 2024*

# kide
