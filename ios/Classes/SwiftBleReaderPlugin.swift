import CoreBluetooth
import CoreLocation
import Flutter
import UIKit

private enum Constants {
  static let serviceUUID = CBUUID(string: "0000b81d-0000-1000-8000-00805f9b34fb")
  static let messageUUID = CBUUID(string: "7db3e235-3608-41f3-a03c-955fcbd2ea4b")
}

public class SwiftBleReaderPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  CBPeripheralManagerDelegate
{
  private let peripheralManager: CBPeripheralManager
  private let eventSink: FlutterEventSink?

  init() {
    peripheralManager = CBPeripheralManager(
      delegate: self, queue: nil,
      options: [CBPeripheralManagerOptionRestoreIdentifierKey: "ble_reader"])
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SwiftBleReaderPlugin()

    let channel = FlutterMethodChannel(
      name: "ble_reader", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler(self)

    let eventChannel = FlutterEventChannel(
      name: "ble_reader_stream", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(self)

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      self.peripheralManager.start()
    case "stop":
      result(FlutterMethodNotImplemented)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments argument: Any?, eventSink: @escaping FlutterEventSink)
    -> FlutterError?
  {
    self.eventSink = eventSink
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = null
    return nil
  }

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    if self.peripheralManager.state == .poweredOn {
      let mutableService: CBMutableService = CBMutableService(
        type: Constants.serviceUUID, primary: true)

      let messageCharacteristic = CBMutableCharacteristic(
        type: Constants.messageUUID,
        properties: [.write],
        value: nil,
        permissions: [.writeable]
      )
      mutableService.characteristic = [messageCharacteristic]

      self.peripheralManager.add(mutableService)
      self.peripheralManager.startAdvertising([
        CBAdvertisementDataServiceUUIDsKey: [Constants.serviceUUID],
        CBAdvertisementDataLocalNameKey: "ble_reader",
      ])
    }
  }

  func peripheralManager(_ peripheral: CBPeripheralManager, willRestore dict: [String: Any]) {
    peripheral.delegate = self
    self.peripheralManager = peripheral

    if !self.peripheralManager.isAdvertising {
      self.peripheralManager.startAdvertising([
        CBAdvertisementDataServiceUUIDsKey: [Constants.serviceUUID],
        CBAdvertisementDataLocalNameKey: "ble_reader",
      ])
    }
  }

  func peripheralManager(
    _ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest
  ) {
    self.peripheralManager.respond(to: request, withResult: .success)
  }

  func peripheralManager(
    _ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]
  ) {
    for request in requests where request.characteristic.uuid == Constants.messageUUID {
      if let value = request.value {
        let valueBytes: [UInt8] = [UInt8](value)
        if let eventSink = self.eventSink {
          eventSink(FlutterStandardTypedData(bytes: valueBytes))
        }

        self.peripheralManager.respond(to: request, withResult: .success)
        return
      }
    }
  }
}