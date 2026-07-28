// camera_service.dart — خدمة الكاميرا وإحداثيات الموقع
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  /// الحصول على الموقع الحالي كنص (إحداثيات + اسم المكان)
  Future<String> getCurrentLocationString() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'خدمة الموقع غير مفعلة';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'إذن الموقع مرفوض';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'إذن الموقع مرفوض دائماً';
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'ar_SA',
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
        return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\n$address';
      }
    } catch (_) {}

    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  }
}
