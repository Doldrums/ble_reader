import 'dart:async';

import 'package:flutter/services.dart';

class BleReader {
  static const MethodChannel _channel = MethodChannel('ble_reader');
  static const EventChannel _timerEventChannel = EventChannel('ble_reader_stream');

  static late Stream<String> _onReceivedDataStream;

  static Future<void> get setupConnection async {
    await _channel.invokeMethod('setup');
  }

  static Stream<String> get receivedDataStream {
    _onReceivedDataStream =
        _timerEventChannel.receiveBroadcastStream()
            .cast<int>()
            .distinct()
            .map((dynamic event) => event as String);
    print(_onReceivedDataStream);

    return _onReceivedDataStream;
  }
}
