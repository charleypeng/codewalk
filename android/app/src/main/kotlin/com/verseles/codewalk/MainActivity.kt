package com.verseles.codewalk

import android.media.RingtoneManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "codewalk/system_sounds"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listNotificationSounds" -> result.success(listNotificationSounds())
                else -> result.notImplemented()
            }
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
