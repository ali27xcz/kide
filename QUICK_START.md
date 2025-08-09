# دليل التشغيل السريع - كيدي

## 🚀 البدء السريع

### 1. متطلبات النظام
- Flutter SDK 3.24.5 أو أحدث
- Dart SDK 3.5.0 أو أحدث
- Android Studio أو VS Code
- جهاز Android أو iOS أو محاكي

### 2. التثبيت
```bash
# استنساخ المشروع
git clone [repository-url]
cd little_scholars_app

# تثبيت التبعيات
flutter pub get

# تشغيل التطبيق
flutter run
```

### 3. التحقق من البيئة
```bash
# التحقق من إعداد Flutter
flutter doctor

# التحقق من الأجهزة المتصلة
flutter devices
```

## 📱 التشغيل على الأجهزة

### Android
```bash
# تشغيل على جهاز Android
flutter run

# بناء APK
flutter build apk --release
```

### iOS
```bash
# تشغيل على جهاز iOS
flutter run

# بناء iOS
flutter build ios --release
```

## 🛠 أوامر مفيدة

### التطوير
```bash
# تشغيل مع Hot Reload
flutter run

# تحليل الكود
flutter analyze

# تشغيل الاختبارات
flutter test

# تنظيف المشروع
flutter clean
```

### البناء
```bash
# بناء للإنتاج (Android)
flutter build apk --release

# بناء AAB (Android App Bundle)
flutter build appbundle --release

# بناء iOS
flutter build ios --release
```

## 🔧 إعداد VS Code

### الإضافات المطلوبة
1. Flutter
2. Dart
3. Flutter Widget Snippets
4. Awesome Flutter Snippets

### إعدادات VS Code
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

## 🎯 الميزات الأساسية

### الشاشات المتاحة
- **Splash Screen**: شاشة البداية
- **Home Screen**: الشاشة الرئيسية
- **Games Menu**: قائمة الألعاب
- **Profile Screen**: الملف الشخصي

### الألعاب المخططة
- لعبة العد (Counting Game)
- لعبة الجمع (Addition Game)
- لعبة الأشكال (Shapes Game)
- لعبة الألوان (Colors Game)
- لعبة الأنماط (Patterns Game)

## 🐛 استكشاف الأخطاء

### مشاكل شائعة
```bash
# مشكلة في التبعيات
flutter clean
flutter pub get

# مشكلة في البناء
flutter clean
flutter pub get
flutter run

# مشكلة في المحاكي
flutter devices
flutter emulators
```

### رسائل الخطأ الشائعة
- **"No devices found"**: تأكد من تشغيل المحاكي أو توصيل الجهاز
- **"Gradle build failed"**: نظف المشروع وأعد البناء
- **"Pod install failed"**: احذف مجلد ios/Pods وأعد التثبيت

## 📚 الموارد المفيدة

### التوثيق
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Widget Catalog](https://flutter.dev/docs/development/ui/widgets)

### المجتمع
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter GitHub](https://github.com/flutter/flutter)

## 🔄 تحديث المشروع

### تحديث Flutter
```bash
# تحديث Flutter SDK
flutter upgrade

# تحديث التبعيات
flutter pub upgrade
```

### تحديث التبعيات
```bash
# عرض التبعيات القديمة
flutter pub outdated

# تحديث تبعية محددة
flutter pub upgrade package_name
```

## 🎨 التخصيص

### تغيير الألوان
عدل ملف `lib/utils/colors.dart`

### إضافة أصوات جديدة
1. أضف الملفات في `assets/sounds/`
2. حدث `pubspec.yaml`
3. حدث `lib/utils/sounds.dart`

### إضافة صور جديدة
1. أضف الملفات في `assets/images/`
2. حدث `pubspec.yaml`
3. استخدم `Image.asset()` في الكود

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من [الأسئلة الشائعة](FAQ.md)
2. ابحث في [Issues](https://github.com/project/issues)
3. أنشئ Issue جديد مع تفاصيل المشكلة

---

**نصيحة**: احتفظ بهذا الملف مفتوحاً أثناء التطوير للرجوع السريع للأوامر! 🚀

