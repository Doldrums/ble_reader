import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ble_reader_method_channel.dart';

abstract class BleReaderPlatform extends PlatformInterface {
  /// Constructs a BleReaderPlatform.
  BleReaderPlatform() : super(token: _token);

  static final Object _token = Object();

  static BleReaderPlatform _instance = MethodChannelBleReader();

  /// The default instance of [BleReaderPlatform] to use.
  ///
  /// Defaults to [MethodChannelBleReader].
  static BleReaderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BleReaderPlatform] when
  /// they register themselves.
  static set instance(BleReaderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
