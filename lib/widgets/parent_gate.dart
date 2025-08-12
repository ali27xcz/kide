import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ParentGate {
  static Future<bool> show(BuildContext context) async {
    final random = Random();
    final int a = 5 + random.nextInt(5); // 5..9
    final int b = 1 + random.nextInt(4); // 1..4
    final bool isAddition = random.nextBool();
    final int answer = isAddition ? a + b : a - b;
    // استخدم محارف العزل الاتجاهي لضمان عرض العملية الحسابية LTR داخل نص عربي
    // اعرض العملية كـ "a - b" مع مسافات صحيحة، واترك علامة الاستفهام العربية خارج العزل.
    final String math = isAddition
        ? '\u2066$a + $b\u2069'
        : '\u2066$a - $b\u2069';
    final String question = 'ما حاصل $math؟';

    final controller = TextEditingController();
    bool verified = false;

    String? errorText;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'بوابة الوالدين',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'للوصول، يرجى حل المسألة:',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'اكتب الإجابة هنا',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.incorrect),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final input = int.tryParse(controller.text.trim());
                              if (input == answer) {
                                verified = true;
                                Navigator.of(dialogContext).pop();
                              } else {
                                setState(() => errorText = 'إجابة غير صحيحة');
                              }
                            },
                            child: const Text('تأكيد'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
    return verified;
  }
}


