package com.verseles.codewalk

import android.content.Intent
import android.media.RingtoneManager
import android.os.Bundle
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Streams partial/final recognition results back to Flutter.
    private var speechRecognizer: SpeechRecognizer? = null
    private var speechEventSink: EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Existing system sounds channel.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "codewalk/system_sounds",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listNotificationSounds" -> result.success(listNotificationSounds())
                else -> result.notImplemented()
            }
        }

        // Speech result event stream — sends Map<text: String, isFinal: Boolean> events.
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "codewalk/speech",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventSink) {
                speechEventSink = sink
            }

            override fun onCancel(args: Any?) {
                speechEventSink = null
            }
        })

        // Speech control channel — accepts 'start' (with optional localeId arg) and 'stop'.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "codewalk/speech_control",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val localeId = call.argument<String?>("localeId")
                    startSpeechRecognition(localeId)
                    result.success(null)
                }
                "stop" -> {
                    stopSpeechRecognition()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Starts Android SpeechRecognizer with EXTRA_ENABLE_PUNCTUATION.
    // EXTRA_ENABLE_PUNCTUATION is a proprietary Google extra — degrades silently
    // on devices without Play Services (STT still works, just without punctuation).
    private fun startSpeechRecognition(localeId: String?) {
        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onEvent(eventType: Int, params: Bundle?) {}

                override fun onResults(bundle: Bundle?) {
                    val results = bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    speechEventSink?.success(
                        mapOf("text" to (results?.firstOrNull() ?: ""), "isFinal" to true),
                    )
                }

                override fun onPartialResults(bundle: Bundle?) {
                    val results = bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    speechEventSink?.success(
                        mapOf("text" to (results?.firstOrNull() ?: ""), "isFinal" to false),
                    )
                }

                override fun onError(error: Int) {
                    // Emit an empty final result so the Flutter side can clean up.
                    speechEventSink?.success(mapOf("text" to "", "isFinal" to true))
                }
            })
            startListening(
                Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(
                        RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                        RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
                    )
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    // Proprietary Google extra for automatic punctuation inference.
                    putExtra("android.speech.extra.ENABLE_PUNCTUATION", true)
                    if (!localeId.isNullOrBlank()) {
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId)
                    }
                },
            )
        }
    }

    private fun stopSpeechRecognition() {
        speechRecognizer?.stopListening()
        speechRecognizer?.destroy()
        speechRecognizer = null
    }

    override fun onDestroy() {
        stopSpeechRecognition()
        super.onDestroy()
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
                ),
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
                    ),
                )
                seenSources.add(uri)
            }
        }

        return items
    }
}
