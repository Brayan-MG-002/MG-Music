package com.mgstu.music

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.IntentFilter

class MainActivity : FlutterActivity() {
	companion object {
		var methodChannel: MethodChannel? = null
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mg_music/notification")

		methodChannel?.setMethodCallHandler { call, result ->
			when (call.method) {
				"show", "update" -> {
					val args = call.arguments as? Map<*, *>
					val title = args?.get("title") as? String ?: ""
					val artist = args?.get("artist") as? String ?: ""
					val artUri = args?.get("artUri") as? String
					val isPlaying = args?.get("isPlaying") as? Boolean ?: false
					NotificationHelper.showNotification(this, title, artist, artUri, isPlaying)
					result.success(null)
				}
				"hide" -> {
					NotificationHelper.hide(this)
					result.success(null)
				}
				"register" -> result.success(null)
				else -> result.notImplemented()
			}
		}

		val filter = IntentFilter()
		filter.addAction("MG_ACTION_PREV")
		filter.addAction("MG_ACTION_PLAY_PAUSE")
		filter.addAction("MG_ACTION_NEXT")
		registerReceiver(NotificationReceiver(), filter)
	}
}
