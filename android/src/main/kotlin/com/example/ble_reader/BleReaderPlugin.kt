package com.example.ble_reader

import android.bluetooth.*
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.util.*

private var gattServer: BluetoothGattServer? = null
private const val TAG = "Server"
val MESSAGE_UUID: UUID = UUID.fromString("7db3e235-3608-41f3-a03c-955fcbd2ea4b")
val SERVICE_UUID: UUID = UUID.fromString("0000b81d-0000-1000-8000-00805f9b34fb")

class BleReaderPlugin() : FlutterPlugin, MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler {
    private var mEventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private lateinit var bluetoothManager: BluetoothManager
    private var gattServerCallback: GattServerCallback? = null

    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }


    private fun setupGattServer(context: Context) {
        bluetoothManager = (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)!!
        gattServerCallback = GattServerCallback()

        gattServer = bluetoothManager.openGattServer(
            context,
            gattServerCallback
        )
        android.util.Log.d(TAG, "setupGattServer: \"${gattServer}\"")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setup" -> {
                context?.let { setupGattServer(it) }
                result.success(true)
            }
            "test" -> result.success(true)
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

        override fun onServiceAdded(status: Int, service: BluetoothGattService?) {
            android.util.Log.d(TAG, "onServiceAdded: \"${service}\"")
            super.onServiceAdded(status, service)
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice?,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic?
        ) {
            android.util.Log.d(TAG, "onCharacteristicReadRequest: \"${device}\"")
            super.onCharacteristicReadRequest(device, requestId, offset, characteristic)
        }

        override fun onDescriptorReadRequest(
            device: BluetoothDevice?,
            requestId: Int,
            offset: Int,
            descriptor: BluetoothGattDescriptor?
        ) {
            android.util.Log.d(TAG, "onDescriptorReadRequest: \"${device}\"")
            super.onDescriptorReadRequest(device, requestId, offset, descriptor)
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            descriptor: BluetoothGattDescriptor?,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            android.util.Log.d(TAG, "onDescriptorWriteRequest: \"${device}\"")
            super.onDescriptorWriteRequest(
                device,
                requestId,
                descriptor,
                preparedWrite,
                responseNeeded,
                offset,
                value
            )
        }

        override fun onExecuteWrite(device: BluetoothDevice?, requestId: Int, execute: Boolean) {
            android.util.Log.d(TAG, "onExecuteWrite: \"${device}\"")
            super.onExecuteWrite(device, requestId, execute)
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
                android.util.Log.d(TAG, "onCharacteristicWriteRequest: Have message: \"$message\"")
                eventSink?.success(message)
            }
        }
    }

    override fun onAttachedToEngine(p0: FlutterPlugin.FlutterPluginBinding) {

        val channel = MethodChannel(p0.getFlutterEngine().getDartExecutor(), "ble_reader")
        channel.setMethodCallHandler(this)

        val eventChannel = EventChannel(p0.getFlutterEngine().getDartExecutor(), "ble_reader_stream")
        eventChannel.setStreamHandler(this)
        context = p0.applicationContext
    }

    override fun onDetachedFromEngine(p0: FlutterPlugin.FlutterPluginBinding) {
        TODO("Not yet implemented")
    }
}