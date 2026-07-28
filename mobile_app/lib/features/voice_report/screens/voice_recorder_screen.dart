// voice_recorder_screen.dart — شاشة التسجيل الصوتي الذكي
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/user_provider.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../services/voice_service.dart';
import '../services/report_service.dart';

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen>
    with SingleTickerProviderStateMixin {
  final _voiceService = VoiceService();
  final _reportService = ReportService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _isProcessing = false;
  String _displayText = '';
  String _finalText = '';
  bool _hasRecording = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkConnectivity();
    _setupVoiceService();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = result == ConnectivityResult.none);
    }
  }

  void _setupVoiceService() {
    _voiceService.onPartialResult = (text) {
      if (mounted) setState(() => _displayText = text);
    };
    _voiceService.onResult = (text) {
      if (mounted) {
        setState(() {
          _finalText = text;
          _displayText = text;
          _hasRecording = text.isNotEmpty;
        });
      }
    };
    _voiceService.onError = (error) {
      if (mounted) AppSnackbar.showError(context, error);
    };
    _voiceService.onStatusChange = (isListening) {
      if (mounted) {
        setState(() => _isListening = isListening);
        if (isListening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    };
  }

  Future<void> _toggleRecording() async {
    if (_isListening) {
      final text = await _voiceService.stopListening();
      setState(() {
        _finalText = text;
        _hasRecording = text.isNotEmpty;
      });
    } else {
      setState(() {
        _displayText = '';
        _finalText = '';
        _hasRecording = false;
      });
      await _voiceService.startListening();
    }
  }

  Future<void> _processWithAI() async {
    if (_finalText.isEmpty) {
      AppSnackbar.showError(context, 'لا يوجد تسجيل صوتي للمعالجة');
      return;
    }

    // التحقق من حد الاستخدام
    final userProvider = context.read<UserProvider>();
    if (!userProvider.canCreateReport) {
      AppSnackbar.showError(
          context, 'وصلت للحد الشهري. اشترك للحصول على تقارير غير محدودة');
      context.push('/home/subscription');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_isOffline) {
        // حفظ محلي للمعالجة لاحقاً
        await _reportService.saveReportLocally(
          voiceText: _finalText,
          projectName: userProvider.user?.displayName,
        );
        if (mounted) {
          AppSnackbar.showInfo(
              context, '📴 تم الحفظ محلياً — سيُعالج عند عودة الإنترنت');
          _resetRecording();
        }
        return;
      }

      // معالجة بالذكاء الاصطناعي
      final processedText = await _reportService.processWithGemini(
        voiceText: _finalText,
        projectName: userProvider.user?.displayName,
        engineerName: userProvider.user?.displayName,
      );

      // حفظ في Firestore
      await _reportService.saveReport(
        voiceText: _finalText,
        processedText: processedText,
      );

      if (mounted) {
        // الانتقال لشاشة المعاينة
        context.push('/home/voice-report/preview',
            extra: {'processedText': processedText, 'voiceText': _finalText});
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _resetRecording() {
    setState(() {
      _displayText = '';
      _finalText = '';
      _hasRecording = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.cancelListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التقرير الصوتي الذكي'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 14, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text('غير متصل',
                      style: TextStyle(fontSize: 11, color: AppColors.warning)),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ===== زر التسجيل الدائري =====
                  _buildRecordButton(),
                  const SizedBox(height: 16),

                  Text(
                    _isListening
                        ? 'جارٍ التسجيل... تحدث بصوت واضح'
                        : _hasRecording
                            ? 'تم التسجيل — راجع النص وارسله للذكاء الاصطناعي'
                            : 'اضغط للتسجيل الصوتي',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isListening
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ===== نص التسجيل =====
                  if (_displayText.isNotEmpty) _buildTranscriptBox(),

                  const SizedBox(height: 20),

                  // ===== نصائح الاستخدام =====
                  if (!_isListening && !_hasRecording) _buildTips(),
                ],
              ),
            ),
          ),

          // ===== أزرار الإجراءات =====
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _toggleRecording,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _isListening
                  ? [AppColors.error, const Color(0xFFFF6B6B)]
                  : _hasRecording
                      ? [AppColors.success, const Color(0xFF4CAF50)]
                      : [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isListening ? AppColors.error : AppColors.primary)
                    .withOpacity(0.4),
                blurRadius: _isListening ? 30 : 20,
                spreadRadius: _isListening ? 5 : 0,
              ),
            ],
          ),
          child: Icon(
            _isListening
                ? Icons.stop_rounded
                : _hasRecording
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded,
            size: 56,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'النص المُسجَّل',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (_hasRecording)
                GestureDetector(
                  onTap: _resetRecording,
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: TextEditingController(text: _displayText)
              ..selection = TextSelection.collapsed(offset: _displayText.length),
            onChanged: (v) => _finalText = v,
            maxLines: null,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'النص سيظهر هنا...',
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 نصائح للتسجيل:',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontSize: 13)),
          const SizedBox(height: 8),
          ...[
            'تحدث بوضوح وبإيقاع طبيعي',
            'اذكر اسم المشروع في البداية',
            'صف ما شاهدته بالتفصيل',
            'يمكنك تعديل النص بعد التسجيل',
          ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Text('• ', style: TextStyle(color: AppColors.accent)),
                  Expanded(
                    child: Text(tip,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ]),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasRecording && !_isListening)
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processWithAI,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white),
              label: Text(
                _isProcessing
                    ? 'يعالج الذكاء الاصطناعي...'
                    : _isOffline
                        ? 'حفظ محلياً للمعالجة لاحقاً'
                        : 'معالجة بالذكاء الاصطناعي ✨',
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
