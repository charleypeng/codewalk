package com.verseles.codewalk

import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val SYSTEM_SOUNDS_CHANNEL = "codewalk/system_sounds"
        private const val SYSTEM_CHANNEL = "codewalk/system"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SYSTEM_SOUNDS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listNotificationSounds" -> result.success(listNotificationSounds())
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SYSTEM_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    startCodeWalkForegroundService()
                    result.success(true)
                }
                "stopForegroundService" -> {
                    stopCodeWalkForegroundService()
                    result.success(true)
                }
                "updateForegroundNotification" -> {
                    val title = call.argument<String>("title") ?: "CodeWalk"
                    val body = call.argument<String>("body")
                        ?: "For reliable notifications"
                    startCodeWalkForegroundService(title = title, body = body)
                    CodeWalkForegroundService.updateContent(this, title, body)
                    result.success(true)
                }
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                "requestDisableBatteryOptimizations" -> {
                    result.success(requestDisableBatteryOptimizations())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startCodeWalkForegroundService(
        title: String? = null,
        body: String? = null,
    ) {
        try {
            val serviceIntent = Intent(this, CodeWalkForegroundService::class.java)
            if (!title.isNullOrBlank()) {
                serviceIntent.putExtra(CodeWalkForegroundService.EXTRA_TITLE, title)
            }
            if (!body.isNullOrBlank()) {
                serviceIntent.putExtra(CodeWalkForegroundService.EXTRA_BODY, body)
            }
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } catch (_: Exception) {
            // No-op: Dart side logs failed calls.
        }
    }

    private fun stopCodeWalkForegroundService() {
        try {
            val serviceIntent = Intent(this, CodeWalkForegroundService::class.java)
            stopService(serviceIntent)
        } catch (_: Exception) {
            // No-op: Dart side logs failed calls.
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        val powerManager = getSystemService(POWER_SERVICE) as? PowerManager
            ?: return false
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestDisableBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }

        return try {
            val powerManager = getSystemService(POWER_SERVICE) as? PowerManager
            val intent = if (
                powerManager != null &&
                    powerManager.isIgnoringBatteryOptimizations(packageName)
            ) {
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            } else {
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun listNotificationSounds(): List<Map<String, String>> {
        val items = mutableListOf<Map<String, String>>()
        val seenSources = mutableSetOf<String>()

        val defaultUri = Settings.System.DEFAULT_NOTIFICATION_URI?.toString()
        if (!defaultUri.isNullOrBlank()) {
            items.add(
                mapOf(
                    "id" to "android_default",
                    "label" to "Android default",
                    "source" to defaultUri,
                )
            )
            seenSources.add(defaultUri)
        }

        val manager = RingtoneManager(this)
        manager.setType(RingtoneManager.TYPE_NOTIFICATION)
        val cursor = manager.cursor ?: return items

        cursor.use {
            while (it.moveToNext()) {
                val title = it.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                val uri = manager.getRingtoneUri(it.position)?.toString()
                if (uri.isNullOrBlank() || seenSources.contains(uri)) {
                    continue
                }
                items.add(
                    mapOf(
                        "id" to "android_${it.position}",
                        "label" to (title ?: "System sound ${it.position + 1}"),
                        "source" to uri,
                    )
                )
                seenSources.add(uri)
            }
        }

        return items
    }
}
