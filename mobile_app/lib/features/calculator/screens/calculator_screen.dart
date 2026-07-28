// calculator_screen.dart — حاسبة الكميات الهندسية الأساسية
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_text_field.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _thicknessController = TextEditingController(); // أو الارتفاع

  String _calcType = 'concrete'; // concrete, block, steel
  String _result = '';

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _thicknessController.dispose();
    super.dispose();
  }

  void _calculate() {
    final l = double.tryParse(_lengthController.text) ?? 0;
    final w = double.tryParse(_widthController.text) ?? 0;
    final t = double.tryParse(_thicknessController.text) ?? 0;

    if (l == 0 || w == 0) {
      setState(() => _result = 'الرجاء إدخال الأبعاد الصحيحة');
      return;
    }

    if (_calcType == 'concrete') {
      // خرسانة: الطول × العرض × السماكة
      if (t == 0) {
        setState(() => _result = 'الرجاء إدخال السماكة للخرسانة');
        return;
      }
      final vol = l * w * t;
      setState(() => _result = 'حجم الخرسانة المطلوب = ${vol.toStringAsFixed(2)} م³');
    } else if (_calcType == 'block') {
      // بلك: مساحة الجدار × عدد البلك في المتر المربع (حوالي 12.5 بلكة مقاس 20x20x40)
      final area = l * w; // هنا الـ w هو الارتفاع
      final blocks = area * 12.5;
      setState(() => _result = 'عدد البلك المطلوب = ${blocks.ceil()} بلكة\n(للبلك مقاس 20×20×40)');
    } else if (_calcType == 'steel') {
      // حديد: مجرد مثال بسيط - وزن المتر الطولي للقطر المختار 
      // سنفترض أن المستخدم أدخل (طول السيخ) في الطول، و(القطر بالملي) في العرض
      final d = w; // القطر
      if (d == 0) {
        setState(() => _result = 'الرجاء إدخال قطر السيخ');
        return;
      }
      // معادلة وزن المتر الطولي = (القطر² / 162)
      final weightPerMeter = (d * d) / 162;
      final totalWeight = weightPerMeter * l;
      setState(() => _result = 'وزن المتر الطولي = ${weightPerMeter.toStringAsFixed(3)} كجم\nالوزن الإجمالي = ${totalWeight.toStringAsFixed(2)} كجم');
    }
  }

  void _reset() {
    _lengthController.clear();
    _widthController.clear();
    _thicknessController.clear();
    setState(() => _result = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حاسبة الكميات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== اختيار نوع الحاسبة =====
            Row(
              children: [
                _buildCalcTypeChip('خرسانة', 'concrete', Icons.foundation_rounded),
                const SizedBox(width: 8),
                _buildCalcTypeChip('بلك', 'block', Icons.grid_view_rounded),
                const SizedBox(width: 8),
                _buildCalcTypeChip('حديد', 'steel', Icons.line_weight_rounded),
              ],
            ),
            const SizedBox(height: 32),

            // ===== المدخلات =====
            Text(
              _calcType == 'steel' ? 'معطيات الحديد' : 'الأبعاد (بالمتر)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            
            CustomTextField(
              controller: _lengthController,
              label: _calcType == 'steel' ? 'إجمالي الطول (م)' : 'الطول (م)',
              hint: 'مثال: 10',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            CustomTextField(
              controller: _widthController,
              label: _calcType == 'steel' ? 'قطر السيخ (مم)' : (_calcType == 'block' ? 'الارتفاع (م)' : 'العرض (م)'),
              hint: _calcType == 'steel' ? 'مثال: 14' : 'مثال: 5',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            if (_calcType == 'concrete')
              CustomTextField(
                controller: _thicknessController,
                label: 'السماكة (م)',
                hint: 'مثال: 0.2',
                keyboardType: TextInputType.number,
              ),

            const SizedBox(height: 32),
            
            // ===== أزرار الحساب =====
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('احسب', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('مسح', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ===== النتيجة =====
            if (_result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('النتيجة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      _result,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcTypeChip(String label, String value, IconData icon) {
    final selected = _calcType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _calcType = value;
          _reset();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : AppColors.textSecondary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Cairo',
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
