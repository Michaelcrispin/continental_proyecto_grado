package com.example.continental

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "continental/whatsapp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enviarWhatsApp") {
                val texto = call.argument<String>("texto") ?: ""
                val telefono = call.argument<String>("telefono") ?: ""
                try {
                    val uri = if (telefono.isNotBlank()) {
                        val limpio = telefono.replace(Regex("[^0-9]"), "")
                        Uri.parse("whatsapp://send?phone=$limpio&text=${Uri.encode(texto)}")
                    } else {
                        Uri.parse("whatsapp://send?text=${Uri.encode(texto)}")
                    }
                    val intent = Intent(Intent.ACTION_VIEW, uri)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    try {
                        val sendIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, texto)
                            setPackage("com.whatsapp")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(sendIntent)
                        result.success(true)
                    } catch (e2: Exception) {
                        result.error("WHATSAPP_ERROR", e2.message, null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
