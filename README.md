# 🌟 Kedy - كيدي

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
</div>

<div align="center">
  <h3>🎓 تطبيق تعليمي تفاعلي للأطفال</h3>
  <p>تطبيق شامل لتعليم الأطفال الأرقام والحروف والألوان والأشكال بطريقة ممتعة وتفاعلية</p>
</div>

---

## 📱 لقطات الشاشة

| الشاشة الرئيسية | قائمة الألعاب | لعبة العد | لعبة الألوان |
|:---:|:---:|:---:|:---:|
| 🏠 | 🎮 | 🔢 | 🎨 |

---

## ✨ الميزات الرئيسية

### 🎮 **الألعاب التعليمية**
- **🔢 لعبة العد**: تعلم الأرقام من 1 إلى 20 مع عرض تفاعلي
- **🔤 تعلم الحروف**: الأبجدية العربية مع 4 أنماط تعلم مختلفة
- **🔺 الأشكال الهندسية**: تعرف على الأشكال المختلفة وخصائصها
- **🎨 تعلم الألوان**: 4 أنماط تفاعلية لتعلم الألوان والأشياء
- **🧩 لعبة البازل**: تطوير المهارات المنطقية وحل المشاكل
- **🧠 لعبة الذاكرة**: تقوية الذاكرة والتركيز

### 🌐 **المميزات التقنية**
- ✅ **دعم متعدد اللغات**: العربية والإنجليزية
- ✅ **Firebase Integration**: المصادقة وقاعدة البيانات السحابية
- ✅ **تتبع التقدم**: نظام نقاط ومستويات متقدم
- ✅ **ملفات شخصية**: إدارة متعددة للأطفال
- ✅ **واجهة حديثة**: تصميم Material Design 3
- ✅ **تأثيرات بصرية**: رسوم متحركة جذابة
- ✅ **تخزين محلي**: يعمل بدون إنترنت

---

## 📥 التحميل والتثبيت

### **📱 تحميل APK (Android)**

| النسخة | الحجم | التوافق | التحميل |
|:---:|:---:|:---:|:---:|
| **عامة** | 25.2 MB | جميع الأجهزة | [تحميل v1.0.0](./release/Kedy-v1.0.0.apk) |
| **محسّنة** | 10.2 MB | الأجهزة الحديثة | [تحميل ARM64](./release/Kedy-v1.0.0-arm64.apk) |

### **🔧 متطلبات النظام**
- **Android**: 4.1+ (API 16)
- **RAM**: 2 GB+
- **مساحة**: 50 MB
- **الإنترنت**: مطلوب لـ Firebase (اختياري)

---

## 🛠️ للمطورين

### **🚀 بدء التطوير**

```bash
# استنساخ المشروع
git clone https://github.com/[username]/kedy.git
cd kedy

# تثبيت Dependencies
flutter pub get

# تشغيل التطبيق
flutter run
```

### **🏗️ بناء Release**

```bash
# تنظيف المشروع
flutter clean && flutter pub get

# بناء APK عام
flutter build apk --release

# بناء APK محسّن (ARM64)
flutter build apk --release --split-per-abi --target-platform android-arm64
```

### **📁 هيكل المشروع**

```
lib/
├── main.dart                 # نقطة الدخول
├── models/                   # نماذج البيانات
│   ├── child_profile.dart
│   ├── game_progress.dart
│   └── achievement.dart
├── screens/                  # شاشات التطبيق
│   ├── auth/                # شاشات المصادقة
│   ├── games/               # شاشات الألعاب
│   └── settings_screen.dart
├── providers/               # إدارة الحالة
│   ├── auth_provider.dart
│   └── language_provider.dart
├── services/               # الخدمات
│   ├── firebase_auth_service.dart
│   ├── firestore_service.dart
│   └── progress_tracker.dart
├── widgets/               # الويدجت المشتركة
├── utils/                # المساعدات والثوابت
└── l10n/                # ملفات الترجمة
```

---

## 🔧 الإعداد

### **🔥 Firebase Setup**

1. إنشاء مشروع Firebase جديد
2. إضافة Android app مع package name: `com.example.little_scholars_app`
3. تحميل `google-services.json` ووضعه في `android/app/`
4. تفعيل Authentication و Firestore

### **📱 Android Setup**

```gradle
// android/app/build.gradle
android {
    compileSdk 33
    
    defaultConfig {
        applicationId "com.example.little_scholars_app"
        minSdk 16
        targetSdk 33
        versionCode 1
        versionName "1.0.0"
    }
}
```

---

## 🎯 خارطة الطريق

### **🔄 الإصدار الحالي (v1.0.0)**
- ✅ 6 ألعاب تعليمية كاملة
- ✅ نظام المصادقة والملفات الشخصية
- ✅ دعم اللغتين العربية والإنجليزية
- ✅ تتبع التقدم والإحصائيات

### **🚀 الإصدارات القادمة**
- 🔮 **v1.1.0**: إضافة الأصوات والموسيقى
- 🔮 **v1.2.0**: ألعاب جديدة (الرياضيات، الكلمات)
- 🔮 **v1.3.0**: وضع الآباء والتقارير المفصلة
- 🔮 **v2.0.0**: دعم iOS ومشاركة التقدم

---

## 🤝 المساهمة

نرحب بالمساهمات! يرجى قراءة [دليل المساهمة](CONTRIBUTING.md) قبل البدء.

### **📋 طرق المساهمة**
- 🐛 الإبلاغ عن الأخطاء
- 💡 اقتراح ميزات جديدة  
- 🔧 تحسين الكود
- 📝 تحسين التوثيق
- 🌍 إضافة لغات جديدة

---

## 📄 الترخيص

هذا المشروع مرخص تحت [MIT License](LICENSE) - راجع ملف LICENSE للتفاصيل.

---

## 📞 التواصل

- **📧 البريد الإلكتروني**: support@littlescholars.app
- **🐛 الأخطاء**: [GitHub Issues](https://github.com/[username]/little_scholars_app/issues)
- **💬 النقاش**: [GitHub Discussions](https://github.com/[username]/little_scholars_app/discussions)

---

<div align="center">
  <p>صنع بـ ❤️ للأطفال العرب</p>
  <p>Made with ❤️ for Arab Children</p>
</div>

---

## 🏆 الشكر والتقدير

- **Flutter Team** - إطار العمل الرائع
- **Firebase** - الخدمات السحابية
- **Material Design** - نظام التصميم
- **المجتمع العربي** - الدعم والمراجعة