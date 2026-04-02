package com.mgstu.music

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File
import com.mgstu.music.NotificationReceiver

class MainActivity : AudioServiceActivity() {

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)


		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mg_music/notification")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"installApk" -> {
						val path = call.argument<String>("path")
						if (path != null) {
							try {
								val file = File(path)
								if (!file.exists()) {
									result.error("FILE_NOT_FOUND", "El archivo APK no existe", null)
									return@setMethodCallHandler
								}
								val uri = FileProvider.getUriForFile(
									this,
									"com.mgstu.music.fileprovider",
									file
								)
								val intent = Intent(Intent.ACTION_VIEW)
								intent.setDataAndType(uri, "application/vnd.android.package-archive")
								intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
								intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
								startActivity(intent)
								result.success(null)
							} catch (e: Exception) {
								result.error("INSTALL_ERROR", e.message, null)
							}
						} else {
							result.error("INVALID_PATH", "Ruta nula", null)
						}
					}

					"show", "update", "hide", "register" -> result.success(null)
					else -> result.notImplemented()
				}
			}
	}
}
