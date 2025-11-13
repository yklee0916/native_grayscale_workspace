import 'package:flutter/material.dart';
import 'channels/image_method_channel.dart';
import 'channels/log_method_channel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Method Channel 초기화
  final imageChannel = ImageMethodChannel();
  imageChannel.initialize();

  final logChannel = LogMethodChannel();
  logChannel.initialize();
}
