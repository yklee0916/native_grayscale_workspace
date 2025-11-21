import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../errors/native_grayscale_sdk_error.dart';
import 'package:log/log.dart';

/// 로그 관리를 위한 Method Channel 관리자 클래스
///
/// Flutter와 네이티브 플랫폼 간 로그 관리 통신을 담당합니다.
class LogMethodChannel with Logger implements LogMessageListener {
  static const String _channelName = 'com.sktelecom.native.grayscale.sdk/log';
  static const MethodChannel _channel = MethodChannel(_channelName);

  @override
  get logTag => "LogMethodChannel";

  /// Method Channel을 초기화하고 핸들러를 설정합니다.
  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  void onLogReport(List<Map<String, String>> logMessages) {
    _channel.invokeMethod("onLogMessage", {'logMessages': logMessages});
  }

  /// Method Call 핸들러
  ///
  /// 네이티브에서 호출된 메서드를 처리합니다.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'setLogInterceptor':
          return await _handleSetLogInterceptor(call);
        case 'setMinimumLogLevel':
          return await _handleSetMinimumLogLevel(call);
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

  Future<void> _handleSetLogInterceptor(MethodCall call) async {
    try {
      var args = call.arguments as Map<dynamic, dynamic>?;
      var enabled = args?['enabled'] ?? false;
      var minimumLogLevel = args?['minimumLogLevel'];
      if (enabled) {
        LogManager().addLogMessageListener(this);
      } else {
        LogManager().dispose();
        LogManager().removeLogMessageListener(this);
      }
      if (minimumLogLevel is String) {
        final level = LogLevel.getByRawValue(minimumLogLevel);
        LogManager().setMinimumLogLevel(level);
      }
      logI("SetLogInterceptor: enabled=$enabled, minimumLogLevel=$minimumLogLevel");
    } catch (e) {
      final error = NativeGrayscaleSDKError.setLogInterceptorError.toMap('Failed to set log interceptor: $e');
      throw PlatformException(
        code: NativeGrayscaleSDKError.setLogInterceptorError.name,
        message: error['error']['message'],
        details: error,
      );
    }
  }

  Future<void> _handleSetMinimumLogLevel(MethodCall call) async {
    try {
      var args = call.arguments as Map<dynamic, dynamic>?;
      logI("_handleSetMinimumLogLevel: $args");
      var minimumLogLevel = args?['minimumLogLevel'];

      if (minimumLogLevel is String) {
        final level = LogLevel.getByRawValue(minimumLogLevel);
        LogManager().setMinimumLogLevel(level);
      }
    } catch (e) {
      final error = NativeGrayscaleSDKError.setMinimumLogLevelError.toMap('Failed to set minimum log level: $e');
      throw PlatformException(
        code: NativeGrayscaleSDKError.setMinimumLogLevelError.name,
        message: error['error']['message'],
        details: error,
      );
    }
  }
}
