package com.example.campus2_0

import android.annotation.SuppressLint
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Исключение из оптимизации батареи: без него многие прошивки
        // (MIUI, EMUI, One UI) не запускают фоновую проверку ЛК.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "omtech/battery")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoring" -> result.success(isIgnoringBatteryOptimizations())
                    "request" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    // Приложение распространяется APK из GitHub Releases, а не через
    // Google Play, поэтому прямой системный запрос допустим.
    @SuppressLint("BatteryLife")
    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val direct = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            .setData(Uri.parse("package:$packageName"))
        try {
            startActivity(direct)
        } catch (_: Exception) {
            // Прошивка без этого диалога — открываем общий список.
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: Exception) {
            }
        }
    }
}
