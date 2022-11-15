import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ble_reader_platform_interface.dart';

/// An implementation of [BleReaderPlatform] that uses method channels.
class MethodChannelBleReader extends BleReaderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ble_reader');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
