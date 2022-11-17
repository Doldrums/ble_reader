import Foundation
import CoreBluetooth
import RxSwift

/// PeripheralManager is a class implementing ReactiveX API which wraps all the Core Bluetooth Peripheral's functions
public class PeripheralManager: ManagerType {

    /// Implementation of CBPeripheralManager
    public let manager: CBPeripheralManager
    let delegateWrapper: CBPeripheralManagerDelegateWrapper

    /// Lock for checking advertising state
    private let advertisingLock = NSLock()
    /// Is there ongoing advertising
    var isAdvertisingOngoing = false
    var restoredAdvertisementData: RestoredAdvertisementData?

    // MARK: Initialization

    /// Creates new `PeripheralManager`
    /// - parameter peripheralManager: `CBPeripheralManager` instance which is used to perform all of the necessary operations
    /// - parameter delegateWrapper: Wrapper on CoreBluetooth's peripheral manager callbacks.
    init(peripheralManager: CBPeripheralManager, delegateWrapper: CBPeripheralManagerDelegateWrapper) {
        self.manager = peripheralManager
        self.delegateWrapper = delegateWrapper
        peripheralManager.delegate = delegateWrapper
    }

    /// Creates new `PeripheralManager` instance. By default all operations and events are executed and received on main thread.
    /// - warning: If you pass background queue to the method make sure to observe results on main thread for UI related code.
    /// - parameter queue: Queue on which bluetooth callbacks are received. By default main thread is used.
    /// - parameter options: An optional dictionary containing initialization options for a peripheral manager.
    /// For more info about it please refer to [Peripheral Manager initialization options](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager/peripheral_manager_initialization_options)
    /// - parameter cbPeripheralManager: Optional instance of `CBPeripheralManager` to be used as a `manager`. If you
    /// skip this parameter, there will be created an instance of `CBPeripheralManager` using given queue and options.
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