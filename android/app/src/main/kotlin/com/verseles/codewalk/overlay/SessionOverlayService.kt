package com.verseles.codewalk.overlay

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.eyedeadevelopment.fluttertts.FlutterTtsPlugin
import com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin
import com.verseles.codewalk.MainActivity
import com.verseles.codewalk.R
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.pathprovider.PathProviderPlugin
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin
import xyz.luan.audioplayers.AudioplayersPlugin

class SessionOverlayService : Service() {
    companion object {
        private const val CHANNEL_ID = "codewalk_session_attention_overlay_v1"
        private const val NOTIFICATION_ID = 9801
        private const val ACTION_STOP = "com.verseles.codewalk.overlay.STOP"

        @Volatile
        private var instance: SessionOverlayService? = null

        fun isRunning(): Boolean = instance != null
    }

    private var engine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private lateinit var windowManager: WindowManager

    override fun onCreate() {
        super.onCreate()
        instance = this
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        startAsForeground()
        if (Settings.canDrawOverlays(this)) {
            attachOverlay()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (!Settings.canDrawOverlays(this)) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (flutterView == null) {
            attachOverlay()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        instance = null
        flutterView?.let { view ->
            view.detachFromFlutterEngine()
            runCatching { windowManager.removeViewImmediate(view) }
        }
        flutterView = null
        engine?.let { flutterEngine ->
            flutterEngine.serviceControlSurface.detachFromService()
            flutterEngine.destroy()
        }
        engine = null
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    private fun attachOverlay() {
        if (engine != null || !Settings.canDrawOverlays(this)) return

        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val flutterEngine = FlutterEngine(applicationContext, null, false, false)
        flutterEngine.plugins.add(AudioplayersPlugin())
        flutterEngine.plugins.add(FlutterSecureStoragePlugin())
        flutterEngine.plugins.add(FlutterTtsPlugin())
        flutterEngine.plugins.add(PathProviderPlugin())
        flutterEngine.plugins.add(SharedPreferencesPlugin())
        flutterEngine.serviceControlSurface.attachToService(this, null, true)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "sessionOverlayAndroidMain",
            ),
        )

        val view = FlutterView(this).also {
            it.attachToFlutterEngine(flutterEngine)
        }
        val size = (96 * resources.displayMetrics.density).toInt()
        val params = WindowManager.LayoutParams(
            size,
            size,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_SECURE,
            PixelFormat.TRANSLUCENT,
        )
        windowManager.addView(view, params)
        engine = flutterEngine
        flutterView = view
    }

    private fun startAsForeground() {
        val stopIntent = Intent(this, SessionOverlayService::class.java).apply {
            action = ACTION_STOP
        }
        val stopAction = PendingIntent.getService(
            this,
            98,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val openAction = PendingIntent.getActivity(
            this,
            99,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_codewalk)
            .setContentTitle("CodeWalk session overlay")
            .setContentText("Session attention overlay is active")
            .setContentIntent(openAction)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(0, "Stop", stopAction)
            .build()
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            notification,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            } else {
                0
            },
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Session attention overlay",
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
    }
}
