// voice_service.dart — خدمة التسجيل الصوتي المحلي (مجاني - بدون API خارجي)
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  String _currentText = '';
  String get currentText => _currentText;
  bool get isListening => _isListening;

  // Callbacks
  Function(String text)? onResult;
  Function(String partialText)? onPartialResult;
  Function(String error)? onError;
  Function(bool isListening)? onStatusChange;

  /// تهيئة خدمة التعرف على الكلام
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // طلب إذن الميكروفون
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      onError?.call('لم يتم منح إذن الميكروفون');
      return false;
    }

    _isInitialized = await _speech.initialize(
      onError: (error) {
        _isListening = false;
        onStatusChange?.call(false);
        onError?.call(_getErrorMessage(error.errorMsg));
        debugPrint('Speech Error: ${error.errorMsg}');
      },
      onStatus: (status) {
        debugPrint('Speech Status: $status');
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          onStatusChange?.call(false);
        }
      },
    );

    return _isInitialized;
  }

  /// بدء التسجيل الصوتي
  Future<void> startListening() async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (_isListening) return;

    _currentText = '';
    _isListening = true;
    onStatusChange?.call(true);

    await _speech.listen(
      onResult: (result) {
        _currentText = result.recognizedWords;
        if (result.finalResult) {
          onResult?.call(_currentText);
        } else {
          onPartialResult?.call(_currentText);
        }
      },
      listenFor: const Duration(minutes: 5), // حد أقصى 5 دقائق
      pauseFor: const Duration(seconds: 4),  // توقف بعد 4 ثوانٍ صمت
      localeId: 'ar_SA',                     // عربي سعودي
      cancelOnError: false,
      partialResults: true,
    );
  }

  /// إيقاف التسجيل
  Future<String> stopListening() async {
    if (!_isListening) return _currentText;

    await _speech.stop();
    _isListening = false;
    onStatusChange?.call(false);
    return _currentText;
  }

  /// إلغاء التسجيل
  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
    _currentText = '';
    onStatusChange?.call(false);
  }

  /// التحقق من دعم اللغة العربية
  Future<bool> isArabicSupported() async {
    if (!_isInitialized) await initialize();
    final locales = await _speech.locales();
    return locales.any((l) => l.localeId.startsWith('ar'));
  }

  String _getErrorMessage(String error) {
    switch (error) {
      case 'error_no_match':
        return 'لم يتم التعرف على الكلام، حاول مجدداً';
      case 'error_speech_timeout':
        return 'انتهت مهلة التسجيل، تحدث بصوت أعلى';
      case 'error_network':
        return 'خطأ في الشبكة — التسجيل الصوتي المحلي يعمل بدون إنترنت';
      case 'error_permission':
        return 'لم يتم منح إذن الميكروفون';
      default:
        return 'خطأ في التسجيل: $error';
    }
  }

  void dispose() {
    _speech.cancel();
  }
}
