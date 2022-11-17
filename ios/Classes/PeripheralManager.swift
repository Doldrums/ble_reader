import Foundation
import CoreBluetooth
import RxSwift

/// PeripheralManager is a class implementing ReactiveX API which wraps all the Core Bluetooth Peripheral's functions
public class PeripheralManager: ManagerType {

    public let manager: CBPeripheralManager
    let delegateWrapper: CBPeripheralManagerDelegateWrapper

    init(peripheralManager: CBPeripheralManager, delegateWrapper: CBPeripheralManagerDelegateWrapper) {
        self.manager = peripheralManager
        self.delegateWrapper = delegateWrapper
        peripheralManager.delegate = delegateWrapper
    }

    public convenience init(queue: DispatchQueue = .main,
                            options: [String: AnyObject]? = nil,
                            cbPeripheralManager: CBPeripheralManager? = nil) {
        let delegateWrapper = CBPeripheralManagerDelegateWrapper()
        let peripheralManager = cbPeripheralManager ??
            CBPeripheralManager(delegate: delegateWrapper, queue: queue, options: options)
    }


    public func observeDidReceiveRead() -> Observable<CBATTRequest> {
        return ensure(.poweredOn, observable: delegateWrapper.didReceiveRead)
    }

    public func observeDidReceiveWrite() -> Observable<[CBATTRequest]> {
        return ensure(.poweredOn, observable: delegateWrapper.didReceiveWrite)
    }

    /// Wrapper for `CBPeripheralManager.respond(to:withResult:)` method
    public func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        manager.respond(to: request, withResult: result)
    }

}