# 🤝 دليل المساهمة - Contributing Guide

شكراً لاهتمامك بالمساهمة في مشروع **Kedy - كيدي**! 🌟

---

## 📋 كيفية المساهمة

### 🐛 **الإبلاغ عن الأخطاء**

1. تأكد من أن الخطأ لم يتم الإبلاغ عنه مسبقاً في [Issues](https://github.com/[username]/little_scholars_app/issues)
2. أنشئ Issue جديد مع:
   - وصف واضح للمشكلة
   - خطوات إعادة إنتاج الخطأ
   - لقطات شاشة إن أمكن
   - معلومات النظام (Android version, device model)

### 💡 **اقتراح ميزات جديدة**

1. ابحث في Issues الموجودة للتأكد من عدم اقتراح الميزة مسبقاً
2. أنشئ Issue مع تسمية `enhancement`
3. اوصف الميزة المقترحة بالتفصيل
4. اشرح كيف ستفيد المستخدمين

### 🔧 **المساهمة بالكود**

#### **إعداد البيئة التطويرية**

```bash
# 1. Fork المشروع على GitHub
# 2. استنساخ Fork الخاص بك
git clone https://github.com/[your-username]/little_scholars_app.git
cd little_scholars_app

# 3. إعداد upstream remote
git remote add upstream https://github.com/[original-username]/little_scholars_app.git

# 4. تثبيت dependencies
flutter pub get

# 5. تشغيل التطبيق للتأكد من العمل
flutter run
```

#### **سير العمل**

```bash
# 1. إنشاء branch جديد
git checkout -b feature/your-feature-name

# 2. تطوير الميزة مع commits واضحة
git add .
git commit -m "feat: add new game feature"

# 3. push للـ fork
git push origin feature/your-feature-name

# 4. إنشاء Pull Request على GitHub
```

---

## 📝 معايير الكود

### **🎯 Flutter/Dart Guidelines**

```dart
// ✅ استخدم أسماء واضحة للمتغيرات والوظائف
class GameProgressTracker {
  void updatePlayerScore(int newScore) {
    // implementation
  }
}

// ✅ أضف تعليقات للوظائف المعقدة
/// Calculates the star rating based on score percentage
/// Returns 1-3 stars based on performance thresholds
int calculateStarRating(double scorePercentage) {
  // implementation
}

// ✅ استخدم const للقيم الثابتة
const Duration animationDuration = Duration(milliseconds: 300);
```

### **📁 تنظيم الملفات**

```
lib/
├── screens/
│   ├── games/
│   │   ├── counting_game_screen.dart
│   │   └── alphabet_game_screen.dart
│   └── auth/
├── widgets/
│   ├── game_button.dart
│   └── animated_character.dart
├── services/
├── providers/
└── utils/
```

### **🎨 UI/UX Guidelines**

- استخدم ألوان `AppColors` المحددة مسبقاً
- اتبع Material Design 3 principles
- تأكد من دعم اللغتين العربية والإنجليزية
- اختبر على شاشات مختلفة الأحجام

---

## 🧪 الاختبار

### **قبل إرسال Pull Request:**

```bash
# 1. تشغيل tests
flutter test

# 2. تحليل الكود
flutter analyze

# 3. تنسيق الكود
dart format .

# 4. بناء التطبيق للتأكد من عدم وجود أخطاء
flutter build apk --debug
```

### **اختبار الألعاب:**
- تأكد من عمل جميع أنماط اللعبة
- اختبر الحالات الحدية (أرقام كبيرة، إجابات خاطئة)
- تأكد من حفظ التقدم بشكل صحيح

---

## 💬 التواصل

### **📞 قنوات التواصل**
- **GitHub Issues**: للأخطاء والاقتراحات
- **GitHub Discussions**: للنقاش العام
- **Pull Request Reviews**: للمراجعة التقنية

### **⏰ أوقات الاستجابة**
- Issues: خلال 2-3 أيام
- Pull Requests: خلال أسبوع
- مراجعة الكود: خلال 3-5 أيام

---

## 🏆 نظام التقدير

### **🌟 مستويات المساهمة**
- **🥉 Bronze**: 1-5 مساهمات
- **🥈 Silver**: 6-15 مساهمة  
- **🥇 Gold**: 16+ مساهمة
- **💎 Diamond**: مساهم أساسي

### **🎁 مكافآت المساهمين**
- إضافة اسمك في قائمة Contributors
- شارة مساهم في ملفك الشخصي
- دعوة للانضمام كـ Core Contributor

---

## 📚 موارد مفيدة

### **📖 مصادر التعلم**
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Guide](https://dart.dev/guides)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Material Design 3](https://m3.material.io/)

### **🛠️ أدوات التطوير**
- **IDE**: VS Code أو Android Studio
- **Extensions**: Flutter, Dart, GitLens
- **Testing**: Flutter Inspector, Dart DevTools

---

## ⚡ نصائح سريعة

- **🔍 اقرأ الكود الموجود** قبل إضافة ميزات جديدة
- **📱 اختبر على أجهزة حقيقية** وليس المحاكي فقط  
- **🌐 تأكد من دعم RTL** للنصوص العربية
- **⚡ فكر في الأداء** عند إضافة رسوم متحركة
- **📊 تتبع التقدم** في الألعاب الجديدة

---

## 🚫 ما يجب تجنبه

- ❌ تغييرات كبيرة بدون نقاش مسبق
- ❌ إضافة dependencies غير ضرورية
- ❌ كسر backward compatibility
- ❌ تجاهل معايير الكود المحددة
- ❌ commits غير واضحة ("fix stuff", "update")

---

<div align="center">
  <p>🙏 شكراً لمساهمتك في تطوير تعليم الأطفال!</p>
  <p>Thank you for contributing to children's education!</p>
</div>
