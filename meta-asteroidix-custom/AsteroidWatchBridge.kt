package org.asteroidos.companion.bridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import java.nio.charset.StandardCharsets

/**
 * Drop-in Android bridge for third-party Android apps to communicate with AsteroidOS
 * applications via Gadgetbridge.
 *
 * Usage Example:
 * ```kotlin
 * val bridge = AsteroidWatchBridge(context)
 *
 * // 1. Send navigation instruction to AsteroidOS map app
 * bridge.sendText("org.asteroidos.map", "nav_maneuver", """{"turn": "left", "dist": 150}""")
 *
 * // 2. Listen for SpO2 measurements from AsteroidOS
 * bridge.registerListener("org.asteroidos.spo2") { appId, action, bytes, jsonStr ->
 *     Log.d("Vitals", "Received $action: $jsonStr")
 * }
 * ```
 */
class AsteroidWatchBridge(private val context: Context) {

    companion object {
        const val ACTION_SEND_TO_WATCH = "nodomain.freeyourgadget.gadgetbridge.ACTION_SEND_TO_WATCH"
        const val ACTION_RECEIVE_FROM_WATCH = "nodomain.freeyourgadget.gadgetbridge.ACTION_RECEIVE_FROM_WATCH"

        const val EXTRA_APP_ID = "extra_app_id"
        const val EXTRA_ACTION = "extra_action"
        const val EXTRA_PAYLOAD_BYTES = "extra_payload_bytes"
        const val EXTRA_PAYLOAD_STRING = "extra_payload_string"
    }

    private var receiver: BroadcastReceiver? = null

    /**
     * Send a string or JSON payload to an AsteroidOS watch application.
     */
    fun sendText(appId: String, action: String, textPayload: String) {
        val intent = Intent(ACTION_SEND_TO_WATCH).apply {
            putExtra(EXTRA_APP_ID, appId)
            putExtra(EXTRA_ACTION, action)
            putExtra(EXTRA_PAYLOAD_STRING, textPayload)
            putExtra(EXTRA_PAYLOAD_BYTES, textPayload.toByteArray(StandardCharsets.UTF_8))
        }
        context.sendBroadcast(intent)
    }

    /**
     * Send raw binary data to an AsteroidOS watch application.
     */
    fun sendBytes(appId: String, action: String, rawPayload: ByteArray) {
        val intent = Intent(ACTION_SEND_TO_WATCH).apply {
            putExtra(EXTRA_APP_ID, appId)
            putExtra(EXTRA_ACTION, action)
            putExtra(EXTRA_PAYLOAD_BYTES, rawPayload)
        }
        context.sendBroadcast(intent)
    }

    /**
     * Register a callback to listen for incoming messages from AsteroidOS applications.
     */
    fun registerListener(
        targetAppId: String? = null,
        onMessageReceived: (appId: String, action: String, payload: ByteArray, payloadString: String?) -> Unit
    ) {
        unregisterListener()
        val filter = IntentFilter(ACTION_RECEIVE_FROM_WATCH)
        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                if (intent?.action == ACTION_RECEIVE_FROM_WATCH) {
                    val appId = intent.getStringExtra(EXTRA_APP_ID) ?: return
                    if (targetAppId != null && appId != targetAppId) return

                    val action = intent.getStringExtra(EXTRA_ACTION) ?: ""
                    val bytes = intent.getByteArrayExtra(EXTRA_PAYLOAD_BYTES) ?: ByteArray(0)
                    val str = intent.getStringExtra(EXTRA_PAYLOAD_STRING)
                    onMessageReceived(appId, action, bytes, str)
                }
            }
        }
        context.registerReceiver(receiver, filter)
    }

    /**
     * Unregister the incoming message listener.
     */
    fun unregisterListener() {
        receiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: Exception) {}
            receiver = null
        }
    }
}
