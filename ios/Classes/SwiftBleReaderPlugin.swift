import Flutter
import UIKit
import CoreLocation
import CoreBluetooth
import RxSwift

public class SwiftBleReaderPlugin: NSObject, FlutterPlugin {

  private let peripheralManager: PeripheralManager
  private let dataReceivedHandler = DataReceivedHandler()

  init(dataReceivedHandler: DataReceivedHandler) {
        self.dataReceivedHandler = dataReceivedHandler
        peripheralManager = PeripheralManager()
        super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ble_reader", binaryMessenger: registrar.messenger())
    let instance = SwiftBleReaderPlugin(dataReceivedHandler: DataReceivedHandler(registrar: registrar))
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch (call.method) {
        case "start":
            dataReceivedHandler.onListen()
        case "stop":
            result(FlutterMethodNotImplemented)
        default:
            result(FlutterMethodNotImplemented)
        }
  }

}
