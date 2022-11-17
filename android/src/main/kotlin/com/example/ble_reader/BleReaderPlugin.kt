package com.example.ble_reader

import android.bluetooth.*
import android.content.Context
import io.flutter.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.*

private var gattServer: BluetoothGattServer? = null
private const val TAG = "Server"
val MESSAGE_UUID: UUID = UUID.fromString("7db3e235-3608-41f3-a03c-955fcbd2ea4b")
val SERVICE_UUID: UUID = UUID.fromString("0000b81d-0000-1000-8000-00805f9b34fb")

class BleReaderPlugin(private var registrar: Registrar) : MethodCallHandler,
    EventChannel.StreamHandler {
    private var mEventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private lateinit var bluetoothManager: BluetoothManager
    private var gattServerCallback: GattServerCallback? = null

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "ble_reader")
            channel.setMethodCallHandler(BleReaderPlugin(registrar))

            val eventChannel = EventChannel(registrar.messenger(), "ble_reader_stream")
            eventChannel.setStreamHandler(BleReaderPlugin(registrar))
        }
    }

    private fun setupGattServer(context: Context) {
        gattServerCallback = GattServerCallback()

        gattServer = bluetoothManager.openGattServer(
            context,
            gattServerCallback
        ).apply {
            addService(setupGattService())
        }
    }

    private fun setupGattService(): BluetoothGattService {
        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        val messageCharacteristic = BluetoothGattCharacteristic(
            MESSAGE_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        )
        service.addCharacteristic(messageCharacteristic)
        return service
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setup" -> context?.let { setupGattServer(it) }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        mEventSink = null
    }

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
        gattServerCallback?.setEventSink(eventSink)
    }

    private class GattServerCallback : BluetoothGattServerCallback() {
        private var eventSink: EventChannel.EventSink? = null

        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }

        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            super.onConnectionStateChange(device, status, newState)
            val isSuccess = status == BluetoothGatt.GATT_SUCCESS
            val isConnected = newState == BluetoothProfile.STATE_CONNECTED
            android.util.Log.d(
                TAG,
                "onConnectionStateChange: Server $device ${device.name} success: $isSuccess connected: $isConnected"
            )
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            super.onCharacteristicWriteRequest(
                device,
                requestId,
                characteristic,
                preparedWrite,
                responseNeeded,
                offset,
                value
            )
            if (characteristic.uuid == MESSAGE_UUID) {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
                val message = value?.toString(Charsets.UTF_8)
                Log.d(TAG, "onCharacteristicWriteRequest: Have message: \"$message\"")
                eventSink?.success(message)
            }
        }
    }
}