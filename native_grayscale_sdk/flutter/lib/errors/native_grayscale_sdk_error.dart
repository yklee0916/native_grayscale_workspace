import 'package:flutter/services.dart';

/// NativeGrayscaleSDK SDK 에러 정의
///
/// 모든 에러 케이스를 enum으로 정의하고, 네이티브로 전달할 수 있는 형식으로 변환합니다.
enum NativeGrayscaleSDKError {
  // Method Channel 관련 에러 (1000번대)
  unknownMethod(1001, 'Unknown method'),
  methodCallError(1002, 'Error handling method call'),

  // Image 처리 관련 에러 (1100번대)
  invalidArgument(1101, 'Invalid argument'),
  imagePathRequired(1102, 'imagePath is required'),
  conversionError(1103, 'Failed to convert image to grayscale'),
  imageFileNotFound(1104, 'Image file not found'),

  // Log 관련 에러 (1200번대)
  setLogInterceptorError(1201, 'Failed to set log interceptor'),
  setMinimumLogLevelError(1202, 'Failed to set minimum log level'),

  // 기타 에러 (9000번대)
  unknownError(9001, 'Unknown error occurred');

  final int code;
  final String defaultMessage;

  const NativeGrayscaleSDKError(this.code, this.defaultMessage);

  /// 에러를 네이티브로 전달할 수 있는 Map 형식으로 변환합니다.
  ///
  /// Returns: {'error': {'code': 1001, 'message': "error desc"}}
  Map<String, dynamic> toMap([String? customMessage]) {
    return {
      'error': {'code': code, 'message': customMessage ?? defaultMessage},
    };
  }

  /// 에러를 PlatformException으로 변환합니다.
  PlatformException toPlatformException([String? customMessage]) {
    return PlatformException(code: name, message: customMessage ?? defaultMessage, details: {'errorCode': code});
  }

  /// Map에서 NativeGrayscaleSDKError를 생성합니다.
  ///
  /// 주로 네이티브에서 받은 에러를 파싱할 때 사용합니다.
  static NativeGrayscaleSDKError? fromMap(Map<dynamic, dynamic>? errorMap) {
    if (errorMap == null) return null;

    final errorCode = errorMap['code'] as int?;
    if (errorCode == null) return null;

    return NativeGrayscaleSDKError.values.firstWhere(
      (e) => e.code == errorCode,
      orElse: () => NativeGrayscaleSDKError.unknownError,
    );
  }
}
