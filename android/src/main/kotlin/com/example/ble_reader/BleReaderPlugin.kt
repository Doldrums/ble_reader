package com.example.ble_reader

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class BleReaderPlugin: FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var channel : MethodChannel
  private var context: Context? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ble_reader")
    channel.setMethodCallHandler(this)


  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }

    try {
      when (call.method) {
        "start" -> result.notImplemented()
        "stop" -> result.notImplemented()
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
//    catch (e: ) {
//      result.error(
//        "No Permission",
//        "No permission for ${e.message} Please ask runtime permission.",
//        "Manifest.permission.${e.message}"
//      )
//    }

  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
    TODO("Not yet implemented")
  }

  override fun onCancel(p0: Any?) {
    TODO("Not yet implemented")
  }
}