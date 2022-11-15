package com.example.ble_reader

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
private const val TAG = "Server"
class BleReaderPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var mEventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ble_reader")
        channel.setMethodCallHandler(this)


    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        try {
            when (call.method) {
                "init" -> initListener()
                "dispose" -> disposeListener()
                "isAdvertising" -> result.notImplemented()
                "isSupported" -> result.notImplemented()
                "isConnected" -> result.notImplemented()
                else -> Handler(Looper.getMainLooper()).post {
                    result.notImplemented()
                }
            }

        } catch (e: Exception) {
            e.message?.let {
                result.error(
                    it,
                    e.localizedMessage,
                    e.stackTrace
                )
            }
        }
    }

    private fun disposeListener() {
        TODO("Not yet implemented")
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    private fun initListener() {
        context?.let { VoiceServer.setupGattServer(it) }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
        createListener(p1)
    }

    private fun createListener(event: EventChannel.EventSink?) {
        TODO("Not yet implemented")
    }

    override fun onCancel(p0: Any?) {
        mEventSink = null
    }
}