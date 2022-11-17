import CoreBluetooth
import OSLog

final class PeripheralManager: NSObject {

//     private let logger = Logger(subsystem: "your app domain here", category: String(describing: PeripheralManager.self))

    private lazy var manager = CBPeripheralManager(delegate: self, queue: nil)
    private let service = CBMutableService(type: Constants.serviceUUID, primary: true)
    private let messageCharacteristic = CBMutableCharacteristic(
        type: Constants.messageUUID,
        properties: .read.union(.write),
        value: nil,
        permissions: .readable.union(.writeable)
    )
    // I'm not sure if you need to use confirmation this way.
    private let confirmCharacteristic = CBMutableCharacteristic(
        type: Constants.confirmUUID,
        properties: .read.union(.write),
        value: nil,
        permissions: .readable.union(.writeable)
    )

    func setupServer() {
        service.characteristics = [messageCharacteristic, confirmCharacteristic]
        manager.add(service)
    }
}

extension PeripheralManager: CBPeripheralManagerDelegate {

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        // You have to handle peripheral setup here. This should be the point where characteristics are available to be used.
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        // Receiving messages here
        for request in requests where request.characteristic.uuid == Constants.messageUUID {
            if
                let data = request.value,
                let message = String(data: data, encoding: .utf8)
            {
                //logger.debug("Received message \(message) from \(request.central.identifier)")
                peripheral.respond(to: request, withResult: .success)
            }
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // I used \() twice because logger methods are using the `OSLogMessage`, not the `String`.
        // Don't worry about it too much, that's just the iOS things.
        //logger.debug("Peripheral changed state to \("\(peripheral.state)")")
    }
}

private enum Constants {

    static let serviceUUID = CBUUID(string: "0000b81d-0000-1000-8000-00805f9b34fb")
    static let messageUUID = CBUUID(string: "7db3e235-3608-41f3-a03c-955fcbd2ea4b")
    static let confirmUUID = CBUUID(string: "7db3e235-3608-41f3-a03c-955fcbd2ea4b")
}
