// stamped_camera_screen.dart — كاميرا الموقع بختم التوثيق
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/user_provider.dart';
import '../../../shared/widgets/app_snackbar.dart';
import 'services/camera_service.dart';

class StampedCameraScreen extends StatefulWidget {
  const StampedCameraScreen({super.key});

  @override
  State<StampedCameraScreen> createState() => _StampedCameraScreenState();
}

class _StampedCameraScreenState extends State<StampedCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  
  final _cameraService = CameraService();
  String _locationText = 'جاري تحديد الموقع...';
  
  // للتحويل لـ صورة مختومة
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  
  // لنتيجة الالتقاط
  XFile? _capturedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _fetchLocation();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) AppSnackbar.showError(context, 'لم يتم العثور على كاميرا');
        return;
      }
      
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'فشل تهيئة الكاميرا');
    }
  }

  Future<void> _fetchLocation() async {
    final loc = await _cameraService.getCurrentLocationString();
    if (mounted) setState(() => _locationText = loc);
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        setState(() => _capturedImage = image);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'خطأ في التقاط الصورة');
    }
  }

  Future<void> _saveStampedImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    
    try {
      // 1. تحويل الـ RepaintBoundary إلى صورة
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. حفظ في المعرض
      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: 'SmartEng_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (result['isSuccess'] == true) {
        if (mounted) {
          AppSnackbar.showSuccess(context, 'تم حفظ الصورة الموثقة في المعرض');
          setState(() => _capturedImage = null);
        }
      } else {
        throw Exception('فشل الحفظ');
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'خطأ أثناء الحفظ');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final userProvider = context.watch<UserProvider>();
    final engineerName = userProvider.user?.displayName ?? 'مهندس';
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_capturedImage != null) {
              setState(() => _capturedImage = null);
            } else {
              context.pop();
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. الصورة (مباشر أو الملتقطة)
                      if (_capturedImage == null)
                        CameraPreview(_controller!)
                      else
                        Image.file(File(_capturedImage!.path), fit: BoxFit.contain),

                      // 2. الختم أسفل يمين الصورة
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.engineering_rounded, color: AppColors.accent, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    engineerName,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    timestamp,
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    _locationText,
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // ===== شريط الأزرار السفلي =====
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_capturedImage == null) ...[
                    // زر التحديث للموقع
                    IconButton(
                      icon: const Icon(Icons.my_location_rounded, color: Colors.white, size: 32),
                      onPressed: _fetchLocation,
                    ),
                    // زر الالتقاط
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // مسافة للتوازن
                  ] else ...[
                    // زر الحفظ
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveStampedImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                          : const Icon(Icons.save_alt_rounded, color: Colors.white),
                        label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ في المعرض', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
