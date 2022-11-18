import CoreBluetooth
import Flutter
import UIKit

private enum Constants {
  static let serviceUUID = CBUUID(string: "0000b81d-0000-1000-8000-00805f9b34fb")
  static let messageUUID = CBUUID(string: "7db3e235-3608-41f3-a03c-955fcbd2ea4b")
}

public class SwiftBleReaderPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  CBPeripheralManagerDelegate
{
  private var peripheralManager: CBPeripheralManager = CBPeripheralManager()
  private var eventSink: FlutterEventSink? = nil

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SwiftBleReaderPlugin()

    let channel = FlutterMethodChannel(
      name: "ble_reader", binaryMessenger: registrar.messenger())

    let eventChannel = FlutterEventChannel(
      name: "ble_reader_stream", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setup":
      self.peripheralManager = CBPeripheralManager(
        delegate: self, queue: nil,
        options: [CBPeripheralManagerOptionRestoreIdentifierKey: "ble_reader"]
      )
      result(true)
    case "test":
      result(true)
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
    self.eventSink = nil
    return nil
  }

  public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    if self.peripheralManager.state == .poweredOn {
      let mutableService: CBMutableService = CBMutableService(
        type: Constants.serviceUUID, primary: true)

      let messageCharacteristic = CBMutableCharacteristic(
        type: Constants.messageUUID,
        properties: [.write],
        value: nil,
        permissions: [.writeable]
      )
      mutableService.characteristics = [messageCharacteristic]

      self.peripheralManager.add(mutableService)
      self.peripheralManager.startAdvertising([
        CBAdvertisementDataServiceUUIDsKey: [Constants.serviceUUID],
        CBAdvertisementDataLocalNameKey: "ble_reader",
      ])
    }
  }

  public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
    peripheral.delegate = self
    self.peripheralManager = peripheral

    if !self.peripheralManager.isAdvertising {
      self.peripheralManager.startAdvertising([
        CBAdvertisementDataServiceUUIDsKey: [Constants.serviceUUID],
        CBAdvertisementDataLocalNameKey: "ble_reader",
      ])
    }
  }

  public func peripheralManager(
    _ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest
  ) {
    self.peripheralManager.respond(to: request, withResult: .success)
  }

  public func peripheralManager(
    _ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]
  ) {
    for request in requests where request.characteristic.uuid == Constants.messageUUID {
      if let value = request.value {
        if let eventSink = self.eventSink {
          eventSink(FlutterStandardTypedData(bytes: value))
        }

        self.peripheralManager.respond(to: request, withResult: .success)
        return
      }
    }
  }
}