package com.verseles.codewalk

import android.content.Intent
import android.media.RingtoneManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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

    // Manual silence timer — Android's EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS
    // is ignored by Google's Speech engine, so we implement silence detection via
    // onRmsChanged: reset the handler when voice is heard, fire stopListening() otherwise.
    private val silenceHandler = Handler(Looper.getMainLooper())
    private var silenceRunnable: Runnable? = null
    private val silenceThresholdDb = 1.5f // dB above which audio is considered speech

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

        // Speech control channel — accepts 'isAvailable', 'start', and 'stop'.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "codewalk/speech_control",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // Returns true when SpeechRecognizer is backed by Google Play Services.
                // Used by Flutter to decide whether to use the native channel or fall
                // back to speech_to_text package (SttSpeechInputService).
                "isAvailable" -> result.success(SpeechRecognizer.isRecognitionAvailable(this))
                "start" -> {
                    val localeId = call.argument<String?>("localeId")
                    val pauseForMs = call.argument<Int>("pauseForMs")?.toLong() ?: 5000L
                    startSpeechRecognition(localeId, pauseForMs)
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

    // Starts Android SpeechRecognizer with automatic formatting and a manual silence
    // timer. EXTRA_ENABLE_FORMATTING (API 33+) requests punctuation/capitalisation
    // from Google's engine; silently ignored on older APIs or non-Google engines.
    // The Android silence-length extras are ignored by Google Speech — we use
    // onRmsChanged to detect actual silence and fire stopListening() ourselves.
    private fun startSpeechRecognition(localeId: String?, pauseForMs: Long) {
        cancelSilenceTimeout()
        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}

                override fun onBeginningOfSpeech() {
                    // Speech began — arm the silence timer from this moment.
                    scheduleSilenceTimeout(pauseForMs)
                }

                override fun onRmsChanged(rmsdB: Float) {
                    // Voice is still active — reset the silence countdown.
                    if (rmsdB > silenceThresholdDb) {
                        scheduleSilenceTimeout(pauseForMs)
                    }
                }

                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onEvent(eventType: Int, params: Bundle?) {}

                override fun onResults(bundle: Bundle?) {
                    cancelSilenceTimeout()
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
                    cancelSilenceTimeout()
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
                    // API 33+ official extra for automatic punctuation and capitalisation.
                    // Uses string key directly so it compiles without minSdk 33 guard;
                    // older Google Speech engines silently ignore unknown extras.
                    putExtra(
                        "android.speech.extra.ENABLE_FORMATTING",
                        "android.speech.extra.FORMATTING_OPTIMIZE_QUALITY",
                    )
                    // Allow punctuation in partial results (API 33+, silently ignored below).
                    putExtra("android.speech.extra.HIDE_PARTIAL_TRAILING_PUNCTUATION", false)
                    if (!localeId.isNullOrBlank()) {
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId)
                    }
                },
            )
        }
    }

    // Arms (or re-arms) the silence timeout. Fires stopListening() after delayMs.
    private fun scheduleSilenceTimeout(delayMs: Long) {
        silenceRunnable?.let { silenceHandler.removeCallbacks(it) }
        val runnable = Runnable { speechRecognizer?.stopListening() }
        silenceRunnable = runnable
        silenceHandler.postDelayed(runnable, delayMs)
    }

    // Cancels any pending silence-timeout callback.
    private fun cancelSilenceTimeout() {
        silenceRunnable?.let { silenceHandler.removeCallbacks(it) }
        silenceRunnable = null
    }

    private fun stopSpeechRecognition() {
        cancelSilenceTimeout()
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
