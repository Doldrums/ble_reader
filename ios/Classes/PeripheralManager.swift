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

    /// Returns the app’s authorization status for sharing data while in the background state.
    /// Wrapper of `CBPeripheralManager.authorizationStatus()` method.
    static var authorizationStatus: CBPeripheralManagerAuthorizationStatus {
        return CBPeripheralManager.authorizationStatus()
    }

    // MARK: State

    public var state: BluetoothState {
        return BluetoothState(rawValue: manager.state.rawValue) ?? .unknown
    }

    public func observeState() -> Observable<BluetoothState> {
        return self.delegateWrapper.didUpdateState.asObservable()
    }

    public func observeStateWithInitialValue() -> Observable<BluetoothState> {
        return Observable.deferred { [weak self] in
            guard let self = self else {
                RxBluetoothKitLog.w("observeState - PeripheralManager deallocated")
                return .never()
            }

            return self.delegateWrapper.didUpdateState.asObservable()
                .startWith(self.state)
        }
    }

    // MARK: Advertising

    /// Starts peripheral advertising on subscription. It create inifinite observable
    /// which emits only one next value, of enum type `StartAdvertisingResult`, just
    /// after advertising start succeeds.
    /// For more info of what specific `StartAdvertisingResult` enum cases means please
    /// refer to ``StartAdvertisingResult` documentation.
    ///
    /// There can be only one ongoing advertising (CoreBluetooth limit).
    /// It will return `advertisingInProgress` error if this method is called when
    /// it is already advertising.
    ///
    /// Advertising is automatically stopped just after disposing of the subscription.
    ///
    /// It can return `BluetoothError.advertisingStartFailed` error, when start advertisement failed
    ///
    /// - parameter advertisementData: Services of peripherals to search for. Nil value will accept all peripherals.
    /// - returns: Infinite observable which emit `StartAdvertisingResult` when advertisement started.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.advertisingInProgress`
    /// * `BluetoothError.advertisingStartFailed`
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func startAdvertising(_ advertisementData: [String: Any]?) -> Observable<StartAdvertisingResult> {
        let observable: Observable<StartAdvertisingResult> = Observable.create { [weak self] observer in
            guard let strongSelf = self else {
                observer.onError(BluetoothError.destroyed)
                return Disposables.create()
            }
            strongSelf.advertisingLock.lock(); defer { strongSelf.advertisingLock.unlock() }
            if strongSelf.isAdvertisingOngoing {
                observer.onError(BluetoothError.advertisingInProgress)
                return Disposables.create()
            }

            strongSelf.isAdvertisingOngoing = true

            var disposable: Disposable?
            if strongSelf.manager.isAdvertising {
                observer.onNext(.attachedToExternalAdvertising(strongSelf.restoredAdvertisementData))
                strongSelf.restoredAdvertisementData = nil
            } else {
                disposable = strongSelf.delegateWrapper.didStartAdvertising
                    .take(1)
                    .map { error in
                        if let error = error {
                            throw BluetoothError.advertisingStartFailed(error)
                        }
                        return .started
                    }
                    .subscribe(onNext: { observer.onNext($0) }, onError: { observer.onError($0)})
                strongSelf.manager.startAdvertising(advertisementData)
            }
            return Disposables.create { [weak self] in
                guard let strongSelf = self else { return }
                disposable?.dispose()
                strongSelf.manager.stopAdvertising()
                do { strongSelf.advertisingLock.lock(); defer { strongSelf.advertisingLock.unlock() }
                    strongSelf.isAdvertisingOngoing = false
                }
            }
        }

        return ensure(.poweredOn, observable: observable)
    }
    
    // MARK: Read & Write

    /// Continuous observer for `CBPeripheralManagerDelegate.peripheralManager(_:didReceiveRead:)` results
    /// - returns: Observable that emits `next` event whenever didReceiveRead occurs.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func observeDidReceiveRead() -> Observable<CBATTRequest> {
        return ensure(.poweredOn, observable: delegateWrapper.didReceiveRead)
    }

    /// Continuous observer for `CBPeripheralManagerDelegate.peripheralManager(_:didReceiveWrite:)` results
    /// - returns: Observable that emits `next` event whenever didReceiveWrite occurs.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func observeDidReceiveWrite() -> Observable<[CBATTRequest]> {
        return ensure(.poweredOn, observable: delegateWrapper.didReceiveWrite)
    }

    /// Wrapper for `CBPeripheralManager.respond(to:withResult:)` method
    public func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        manager.respond(to: request, withResult: result)
    }

    // MARK: Updating value

    /// Wrapper for `CBPeripheralManager.updateValue(_:for:onSubscribedCentrals:)` method
    public func updateValue(
        _ value: Data,
        for characteristic: CBMutableCharacteristic,
        onSubscribedCentrals centrals: [CBCentral]?) -> Bool {
        return manager.updateValue(value, for: characteristic, onSubscribedCentrals: centrals)
    }

    /// Continuous observer for `CBPeripheralManagerDelegate.peripheralManagerIsReady(toUpdateSubscribers:)` results
    /// - returns: Observable that emits `next` event whenever isReadyToUpdateSubscribers occurs.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func observeIsReadyToUpdateSubscribers() -> Observable<Void> {
        return ensure(.poweredOn, observable: delegateWrapper.isReady)
    }

    // MARK: Subscribing

    /// Continuous observer for `CBPeripheralManagerDelegate.peripheralManager(_:central:didSubscribeTo:)` results
    /// - returns: Observable that emits `next` event whenever didSubscribeTo occurs.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func observeOnSubscribe() -> Observable<(CBCentral, CBCharacteristic)> {
        return ensure(.poweredOn, observable: delegateWrapper.didSubscribeTo)
    }

    /// Continuous observer for `CBPeripheralManagerDelegate.peripheralManager(_:central:didUnsubscribeFrom:)` results
    /// - returns: Observable that emits `next` event whenever didUnsubscribeFrom occurs.
    ///
    /// It's **infinite** stream, so `.complete` is never called.
    ///
    /// Observable can ends with following errors:
    /// * `BluetoothError.destroyed`
    /// * `BluetoothError.bluetoothUnsupported`
    /// * `BluetoothError.bluetoothUnauthorized`
    /// * `BluetoothError.bluetoothPoweredOff`
    /// * `BluetoothError.bluetoothInUnknownState`
    /// * `BluetoothError.bluetoothResetting`
    public func observeOnUnsubscribe() -> Observable<(CBCentral, CBCharacteristic)> {
        return ensure(.poweredOn, observable: delegateWrapper.didUnsubscribeFrom)
    }

    // MARK: Internal functions

    func ensureValidStateAndCallIfSucceeded<T>(for observable: Observable<T>,
                                               postSubscriptionCall call: @escaping () -> Void
        ) -> Observable<T> {
        let operation = Observable<T>.deferred {
            call()
            return .empty()
        }
        return ensure(.poweredOn, observable: Observable.merge([observable, operation]))
    }
}