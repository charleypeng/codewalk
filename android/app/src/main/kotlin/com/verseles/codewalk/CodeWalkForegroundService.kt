package com.verseles.codewalk

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class CodeWalkForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "codewalk_background_monitor"
        private const val CHANNEL_NAME = "CodeWalk background monitor"
        private const val CHANNEL_DESCRIPTION = "Keeps CodeWalk background monitoring active"
        private const val NOTIFICATION_ID = 11001

        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_BODY = "extra_body"

        private var instance: CodeWalkForegroundService? = null

        fun isRunning(): Boolean {
            return instance != null
        }

        fun updateContent(context: Context, title: String, body: String) {
            val notification = buildNotification(context, title, body)
            val service = instance
            if (service != null) {
                service.startForeground(NOTIFICATION_ID, notification)
                return
            }

            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, notification)
        }

        private fun buildNotification(
            context: Context,
            title: String,
            body: String,
        ): Notification {
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            return NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_codewalk)
                .setContentTitle(title)
                .setContentText(body)
                .setContentIntent(openPendingIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .build()
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE)
            ?: "Monitoring one of session"
        val body = intent?.getStringExtra(EXTRA_BODY)
            ?: "For reliable notifications"
        startForeground(NOTIFICATION_ID, buildNotification(this, title, body))
        return START_STICKY
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = CHANNEL_DESCRIPTION
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }
}
