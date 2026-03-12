package com.mgstu.music

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationReceiver : BroadcastReceiver() {
    /** Recibe acciones de la notificación y las reenvía a Flutter */
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        Log.d("NotificationReceiver", "Acción recibida: $action")
        try {
            MainActivity.methodChannel?.invokeMethod("notificationAction", mapOf("action" to action))
        } catch (e: Exception) {
            Log.e("NotificationReceiver", "Error: ${e.message}")
        }
    }
}
