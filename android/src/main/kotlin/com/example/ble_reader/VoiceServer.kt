//package com.example.ble_reader
//
//import android.bluetooth.*
//import android.content.Context
//import android.os.Build
//import android.util.Log
//import androidx.annotation.RequiresApi
//import java.util.*
//import java.util.stream.Stream
//
//object VoiceServer {
//    private var gattServer: BluetoothGattServer? = null
//    private var gattServerCallback: BluetoothGattServerCallback? = null
//
//    @RequiresApi(Build.VERSION_CODES.N)
//    private var data: Stream<String> = Stream.empty()
//    private lateinit var bluetoothManager: BluetoothManager
//
//
//    fun setupGattServer(context: Context) {
//        gattServerCallback = GattServerCallback()
//
//        gattServer = bluetoothManager.openGattServer(
//            context,
//            gattServerCallback
//        ).apply {
//            addService(setupGattService())
//        }
//    }
//
//    private fun setupGattService(): BluetoothGattService {
//        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
//        val messageCharacteristic = BluetoothGattCharacteristic(
//            MESSAGE_UUID,
//            BluetoothGattCharacteristic.PROPERTY_WRITE,
//            BluetoothGattCharacteristic.PERMISSION_WRITE
//        )
//        service.addCharacteristic(messageCharacteristic)
//        val confirmCharacteristic = BluetoothGattCharacteristic(
//            CONFIRM_UUID,
//            BluetoothGattCharacteristic.PROPERTY_WRITE,
//            BluetoothGattCharacteristic.PERMISSION_WRITE
//        )
//        service.addCharacteristic(confirmCharacteristic)
//        return service
//    }
//
//    class GattServerCallback() : BluetoothGattServerCallback() {
//
//        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
//            super.onConnectionStateChange(device, status, newState)
//            val isSuccess = status == BluetoothGatt.GATT_SUCCESS
//            val isConnected = newState == BluetoothProfile.STATE_CONNECTED
//            Log.d(
//                TAG,
//                "onConnectionStateChange: Server $device ${device.name} success: $isSuccess connected: $isConnected"
//            )
//        }
//
//        override fun onCharacteristicWriteRequest(
//            device: BluetoothDevice,
//            requestId: Int,
//            characteristic: BluetoothGattCharacteristic,
//            preparedWrite: Boolean,
//            responseNeeded: Boolean,
//            offset: Int,
//            value: ByteArray?
//        ) {
//            super.onCharacteristicWriteRequest(
//                device,
//                requestId,
//                characteristic,
//                preparedWrite,
//                responseNeeded,
//                offset,
//                value
//            )
//            if (characteristic.uuid == MESSAGE_UUID) {
//                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
//                val message = value?.toString(Charsets.UTF_8)
//                Log.d(TAG, "onCharacteristicWriteRequest: Have message: \"$message\"")
//
//                data.message?.let {
//                    _messages.postValue(message)
//                }
//            }
//        }
//    }
//}