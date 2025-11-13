import 'package:flutter/services.dart';
import 'package:grayscale/grayscale.dart';
import '../errors/native_grayscale_sdk_error.dart';
import 'package:log/log.dart';

/// 이미지 처리를 위한 Method Channel 관리자 클래스
///
/// Flutter와 네이티브 플랫폼 간 이미지 처리 통신을 담당합니다.
class ImageMethodChannel with Logger {
  static const String _channelName = 'com.sktelecom.native.grayscale.sdk/image';
  static const MethodChannel _channel = MethodChannel(_channelName);

  @override
  get logTag => "ImageMethodChannel";

  /// Method Channel을 초기화하고 핸들러를 설정합니다.
  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Method Call 핸들러
  ///
  /// 네이티브에서 호출된 메서드를 처리합니다.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'convertToGrayscale':
          return await _handleConvertToGrayscale(call);
        default:
          final error = NativeGrayscaleSDKError.unknownMethod.toMap('Unknown method: ${call.method}');
          throw PlatformException(
            code: NativeGrayscaleSDKError.unknownMethod.name,
            message: error['error']['message'],
            details: error,
          );
      }
    } catch (e) {
      if (e is PlatformException && e.details is Map && (e.details as Map).containsKey('error')) {
        rethrow;
      }
      final error = NativeGrayscaleSDKError.methodCallError.toMap('Error handling method call: ${call.method} - $e');
      throw PlatformException(
        code: NativeGrayscaleSDKError.methodCallError.name,
        message: error['error']['message'],
        details: error,
      );
    }
  }

  /// Grayscale 변환 메서드 핸들러
  Future<Map<String, dynamic>> _handleConvertToGrayscale(MethodCall call) async {
    try {
      final String? imagePath = call.arguments?['imagePath'] as String?;
      if (imagePath == null || imagePath.isEmpty) {
        final error = NativeGrayscaleSDKError.imagePathRequired.toMap();
        throw PlatformException(
          code: NativeGrayscaleSDKError.imagePathRequired.name,
          message: error['error']['message'],
          details: error,
        );
      }
      final String resultPath = await Grayscale.convertToGrayscale(imagePath);
      logI("convertToGrayscale success: $resultPath");
      return {'resultPath': resultPath};
    } catch (e) {
      logE("convertToGrayscale failed: $e");
      if (e is PlatformException && e.details is Map && (e.details as Map).containsKey('error')) {
        rethrow;
      }
      final error = NativeGrayscaleSDKError.conversionError.toMap('Failed to convert image to grayscale: $e');
      throw PlatformException(
        code: NativeGrayscaleSDKError.conversionError.name,
        message: error['error']['message'],
        details: error,
      );
    }
  }
}
