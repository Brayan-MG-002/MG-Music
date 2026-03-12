package com.mgstu.music

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.IntentFilter

class MainActivity : AudioServiceActivity() {
	/** Canal para comunicar acciones de notificación entre Android y Flutter */
	companion object {
		var methodChannel: MethodChannel? = null
	}

	/** Configura el motor de Flutter, crea el canal y registra el BroadcastReceiver */
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
					val isFavorite = args?.get("isFavorite") as? Boolean ?: false
					val isAdo = args?.get("isAdo") as? Boolean ?: false
					val showPrevious = args?.get("showPrevious") as? Boolean ?: true
					val showNext = args?.get("showNext") as? Boolean ?: true

					NotificationHelper.showNotification(
						this,
						title,
						artist,
						artUri,
						isPlaying,
						isFavorite,
						isAdo,
						showPrevious,
						showNext
					)
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
		filter.addAction("MG_ACTION_FAVORITE")
		filter.addAction("MG_ACTION_STOP")

		if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
			registerReceiver(NotificationReceiver(), filter, android.content.Context.RECEIVER_NOT_EXPORTED)
		} else {
			registerReceiver(NotificationReceiver(), filter)
		}
	}
}
