package com.mgstu.music

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

object NotificationHelper {
    private const val CHANNEL_ID = "mg_music_custom_channel"
    private const val NOTIF_ID = 1001
    private const val TAG = "NotificationHelper"

    fun showNotification(context: Context, title: String, artist: String, artPath: String?, isPlaying: Boolean) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val ch = NotificationChannel(CHANNEL_ID, "MG Music", NotificationManager.IMPORTANCE_LOW)
                nm.createNotificationChannel(ch)
            }

            val pkg = context.packageName
            Log.d(TAG, "Creando notificación personalizada para: $title - $artist")

            val remote = RemoteViews(pkg, R.layout.notification_custom)
            remote.setTextViewText(R.id.notification_title, title)
            remote.setTextViewText(R.id.notification_artist, artist)

            // Art
            if (artPath != null) {
                try {
                    val uri = android.net.Uri.parse(artPath)
                    val bmp = decodeSampledBitmapFromUri(context, uri, 256, 256)
                    if (bmp != null) {
                        remote.setImageViewBitmap(R.id.notification_art, bmp)
                    } else {
                        remote.setImageViewResource(R.id.notification_art, R.mipmap.ic_launcher)
                    }
                } catch (e: Throwable) {
                    Log.e(TAG, "Error seguro cargando artwork: ${e.message}")
                    remote.setImageViewResource(R.id.notification_art, R.mipmap.ic_launcher)
                }
            } else {
                remote.setImageViewResource(R.id.notification_art, R.mipmap.ic_launcher)
            }

            val prevIntent = Intent(context, NotificationReceiver::class.java).apply {
                action = "MG_ACTION_PREV"
                setPackage(pkg)
            }
            val playIntent = Intent(context, NotificationReceiver::class.java).apply {
                action = "MG_ACTION_PLAY_PAUSE"
                setPackage(pkg)
            }
            val nextIntent = Intent(context, NotificationReceiver::class.java).apply {
                action = "MG_ACTION_NEXT"
                setPackage(pkg)
            }

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val prev = PendingIntent.getBroadcast(context, 1, prevIntent, flags)
            val play = PendingIntent.getBroadcast(context, 2, playIntent, flags)
            val next = PendingIntent.getBroadcast(context, 3, nextIntent, flags)

            remote.setOnClickPendingIntent(R.id.btn_prev, prev)
            remote.setOnClickPendingIntent(R.id.btn_play, play)
            remote.setOnClickPendingIntent(R.id.btn_next, next)

            val playIcon = if (isPlaying) R.drawable.ic_pause_white_24dp else R.drawable.ic_play_arrow_white_24dp
            remote.setImageViewResource(R.id.btn_play, playIcon)

            Log.d(TAG, "Botones configurados: prev, play, next")

            val notification: Notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_music)
                .setCustomContentView(remote)
                .setOnlyAlertOnce(true)
                .setOngoing(true)
                .build()

            nm.notify(NOTIF_ID, notification)
        } catch (e: Throwable) {
            Log.e(TAG, "Error mostrando notificación: ${e.message}", e)
        }
    }

    fun hide(context: Context) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(NOTIF_ID)
            Log.d(TAG, "Notificación ocultada")
        } catch (e: Exception) {
            Log.e(TAG, "Error ocultando notificación: ${e.message}")
        }
    }


    private fun decodeSampledBitmapFromUri(context: Context, uri: android.net.Uri, reqWidth: Int, reqHeight: Int): android.graphics.Bitmap? {
        try {
            var input = context.contentResolver.openInputStream(uri) ?: return null
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
                inPreferredConfig = android.graphics.Bitmap.Config.RGB_565 // Reduce memoria al 50%
            }
            BitmapFactory.decodeStream(input, null, options)
            input.close()

            options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight)

            options.inJustDecodeBounds = false
            options.inPreferredConfig = android.graphics.Bitmap.Config.RGB_565
            input = context.contentResolver.openInputStream(uri) ?: return null
            val bmp = BitmapFactory.decodeStream(input, null, options)
            input.close()
            return bmp
        } catch (e: Exception) {
            return null
        }
    }

    private fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val (height: Int, width: Int) = options.run { outHeight to outWidth }
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2

            while ((halfHeight / inSampleSize) >= reqHeight && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }
}