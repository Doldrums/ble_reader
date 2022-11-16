import 'package:flutter/services.dart';

class BleReader {
  /// Singleton instance
  static final BleReader _instance = BleReader._internal();

  /// Singleton factory
  factory BleReader() {
    return _instance;
  }

  /// Singleton constructor
  BleReader._internal();

  Stream<String>? _dataStream;

  final EventChannel _dataChangedEventChannel = const EventChannel(
    'ble_reader',
  );

  Stream<String> get onData {
    _dataStream ??= _dataChangedEventChannel
        .receiveBroadcastStream()
        .cast<int>()
        .distinct()
        .map((dynamic event) => event as String);
    return _dataStream!;
  }
}
