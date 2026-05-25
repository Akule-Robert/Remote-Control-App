package com.wifiremote.wifi_tv_remote

import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "wifi_tv_remote/multicast")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquireLock" -> {
                        val wifi = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
                        multicastLock = wifi.createMulticastLock("mdns_lock").also {
                            it.setReferenceCounted(true)
                            it.acquire()
                        }
                        result.success(null)
                    }
                    "releaseLock" -> {
                        multicastLock?.takeIf { it.isHeld }?.release()
                        multicastLock = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
