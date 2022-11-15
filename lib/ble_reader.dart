
import 'ble_reader_platform_interface.dart';

class BleReader {
  Future<String?> getPlatformVersion() {
    return BleReaderPlatform.instance.getPlatformVersion();
  }
}
