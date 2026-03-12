package com.mgstu.music

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

object NotificationHelper {
    private const val CHANNEL_ID = "com.mgstudios.mgmusic.audio"
    private const val NOTIF_ID = 1121
    private const val TAG = "NotificationHelper"

    /** Muestra o actualiza la notificación de reproducción con acciones compactas */
    fun showNotification(
        context: Context,
        title: String,
        artist: String,
        artPath: String?,
        isPlaying: Boolean,
        isFavorite: Boolean,
        isAdo: Boolean,
        showPrevious: Boolean,
        showNext: Boolean
    ) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val ch = NotificationChannel(CHANNEL_ID, "MG Music", NotificationManager.IMPORTANCE_LOW)
                nm.createNotificationChannel(ch)
            }

            val pkg = context.packageName
            Log.d(TAG, "Creando notificación nativa para: $title - $artist")
            val artwork = loadArtwork(context, artPath)

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
            val favoriteIntent = Intent(context, NotificationReceiver::class.java).apply {
                action = "MG_ACTION_FAVORITE"
                setPackage(pkg)
            }
            val stopIntent = Intent(context, NotificationReceiver::class.java).apply {
                action = "MG_ACTION_STOP"
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
            val favorite = PendingIntent.getBroadcast(context, 4, favoriteIntent, flags)
            val stop = PendingIntent.getBroadcast(context, 5, stopIntent, flags)

            val stopIcon = R.drawable.ic_close_white_24dp
            val playIcon = if (isPlaying) R.drawable.ic_pause_white_24dp else R.drawable.ic_play_arrow_white_24dp
            val favoriteIcon = if (isFavorite) android.R.drawable.btn_star_big_on else android.R.drawable.btn_star_big_off

            val launchIntent = context.packageManager.getLaunchIntentForPackage(pkg)
            val contentIntent = launchIntent?.let {
                PendingIntent.getActivity(context, 100, it, flags)
            }

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_music)
                .setContentTitle(title)
                .setContentText(artist)
                .setOnlyAlertOnce(true)
                .setOngoing(isPlaying)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_MAX)

            if (contentIntent != null) {
                builder.setContentIntent(contentIntent)
            }
            if (artwork != null) {
                builder.setLargeIcon(artwork)
            }

            val compactActionIndices = mutableListOf<Int>()
            var actionIndex = 0

            // 0: STOP (X)
            builder.addAction(stopIcon, "Cerrar", stop)
            compactActionIndices.add(actionIndex)
            actionIndex++

            // 1: PREV
            if (showPrevious) {
                builder.addAction(R.drawable.ic_skip_previous_white_24dp, "Anterior", prev)
                compactActionIndices.add(actionIndex)
                actionIndex++
            }

            // 2: PLAY/PAUSE
            builder.addAction(playIcon, if (isPlaying) "Pausar" else "Reproducir", play)
            compactActionIndices.add(actionIndex)
            actionIndex++

            // 3: NEXT
            if (showNext) {
                builder.addAction(R.drawable.ic_skip_next_white_24dp, "Siguiente", next)
                compactActionIndices.add(actionIndex)
                actionIndex++
            }

            // 4: FAVORITE (ESTRELLA/HEART)
            builder.addAction(favoriteIcon, if (isFavorite) "Quitar favorito" else "Favorito", favorite)
            actionIndex++

            val compact = compactActionIndices.toIntArray()
            val mediaStyle = androidx.media.app.NotificationCompat.MediaStyle()
            if (compact.isNotEmpty()) {
                mediaStyle.setShowActionsInCompactView(*compact)
            }
            builder.setStyle(mediaStyle)

            val notification: Notification = builder.build()

            nm.notify(NOTIF_ID, notification)
        } catch (e: Throwable) {
            Log.e(TAG, "Error mostrando notificación: ${e.message}", e)
        }
    }

    /** Oculta la notificación activa del reproductor */
    fun hide(context: Context) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(NOTIF_ID)
            Log.d(TAG, "Notificación ocultada")
        } catch (e: Exception) {
            Log.e(TAG, "Error ocultando notificación: ${e.message}")
        }
    }


    /** Carga la carátula desde un URI si está disponible */
    private fun loadArtwork(context: Context, artPath: String?): Bitmap? {
        if (artPath == null) return null
        return try {
            val uri = android.net.Uri.parse(artPath)
            decodeSampledBitmapFromUri(context, uri, 256, 256)
        } catch (_: Throwable) {
            null
        }
    }

    /** Decodifica un bitmap reducido para evitar uso excesivo de memoria */
    private fun decodeSampledBitmapFromUri(context: Context, uri: android.net.Uri, reqWidth: Int, reqHeight: Int): Bitmap? {
        try {
            var input = context.contentResolver.openInputStream(uri) ?: return null
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
                inPreferredConfig = Bitmap.Config.RGB_565
            }
            BitmapFactory.decodeStream(input, null, options)
            input.close()

            options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight)

            options.inJustDecodeBounds = false
            options.inPreferredConfig = Bitmap.Config.RGB_565
            input = context.contentResolver.openInputStream(uri) ?: return null
            val bmp = BitmapFactory.decodeStream(input, null, options)
            input.close()
            return bmp
        } catch (e: Exception) {
            return null
        }
    }

    /** Calcula el factor de muestreo ideal según dimensiones requeridas */
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
