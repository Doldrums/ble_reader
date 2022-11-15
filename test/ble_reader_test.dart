import 'package:flutter_test/flutter_test.dart';
import 'package:ble_reader/ble_reader.dart';
import 'package:ble_reader/ble_reader_platform_interface.dart';
import 'package:ble_reader/ble_reader_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBleReaderPlatform
    with MockPlatformInterfaceMixin
    implements BleReaderPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BleReaderPlatform initialPlatform = BleReaderPlatform.instance;

  test('$MethodChannelBleReader is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBleReader>());
  });

  test('getPlatformVersion', () async {
    BleReader bleReaderPlugin = BleReader();
    MockBleReaderPlatform fakePlatform = MockBleReaderPlatform();
    BleReaderPlatform.instance = fakePlatform;

    expect(await bleReaderPlugin.getPlatformVersion(), '42');
  });
}
