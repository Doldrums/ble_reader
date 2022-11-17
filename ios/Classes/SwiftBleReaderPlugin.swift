import Flutter
import UIKit
import CoreLocation
import CoreBluetooth
import RxSwift

public class SwiftBleReaderPlugin: NSObject, FlutterPlugin {

  private let peripheralManager = PeripheralManager()
  private let dataReceivedHandler = DataReceivedHandler()

  init(stateChangedHandler: StateChangedHandler) {
        self.stateChangedHandler = stateChangedHandler
        flutterBlePeripheralManager = FlutterBlePeripheralManager(stateChangedHandler: stateChangedHandler)
        super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ble_reader", binaryMessenger: registrar.messenger())
    let instance = SwiftBleReaderPlugin(stateChangedHandler: StateChangedHandler(registrar: registrar))
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Event channel
    instance.dataReceivedHandler.register(with: registrar, peripheral: peripheralManager)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch (call.method) {
        case "start":
            result(FlutterMethodNotImplemented)
        case "stop":
            result(FlutterMethodNotImplemented)
        default:
            result(FlutterMethodNotImplemented)
        }
  }
}
