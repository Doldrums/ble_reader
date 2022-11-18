import 'dart:async';

import 'package:flutter/services.dart';

class BleReader {
  static const MethodChannel _channel = MethodChannel('ble_reader');
  static const EventChannel _timerEventChannel = EventChannel(
      'ble_reader_stream');

  static late Stream<dynamic> _onReceivedDataStream;

  static Future<bool> get setupConnection async {
    return await _channel.invokeMethod('setup');
  }

  static Future<bool> get testService async {
    return await _channel.invokeMethod('test');
  }

  static Stream<dynamic> get receivedDataStream {
    _onReceivedDataStream =
        _timerEventChannel.receiveBroadcastStream();
    print(_onReceivedDataStream);

    return _onReceivedDataStream;
  }
}
