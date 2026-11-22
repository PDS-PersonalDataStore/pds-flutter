package top.tau2c.pds.flutter.pds_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import top.tau2c.pds.client.PdsAndroidClient

/**
 * Android implementation of the PDS Flutter plugin bridging Flutter to PdsAndroidClient.
 */
class PdsFlutterPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware, PluginRegistry.ActivityResultListener {

    companion object {
        private const val REQUEST_CODE_AUTH = 4284
    }

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingAuthResult: Result? = null
    private var pdsClient: PdsAndroidClient? = null

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val changeListener = PdsAndroidClient.ChangeListener { changeEventsJson ->
        mainHandler.post {
            eventSink?.success(changeEventsJson)
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        pdsClient = PdsAndroidClient(context)

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "top.tau2c.pds/client")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "top.tau2c.pds/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val client = pdsClient ?: run {
            result.error("NOT_INITIALIZED", "PDS Client is not initialized", null)
            return
        }

        when (call.method) {
            "connect" -> {
                try {
                    val connected = client.connect()
                    result.success(connected)
                } catch (e: Exception) {
                    result.error("CONNECT_ERROR", e.message, null)
                }
            }
            "disconnect" -> {
                try {
                    client.disconnect()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("DISCONNECT_ERROR", e.message, null)
                }
            }
            "isConnected" -> {
                result.success(client.isConnected())
            }
            "isReady" -> {
                result.success(client.isReady())
            }
            "executeRawRequest" -> {
                val requestJson = call.argument<String>("requestJson")
                if (requestJson == null) {
                    result.error("INVALID_ARGUMENT", "requestJson must not be null", null)
                    return
                }
                try {
                    val responseJson = client.executeRawRequest(requestJson)
                    result.success(responseJson)
                } catch (e: Exception) {
                    result.error("EXECUTE_ERROR", e.message, null)
                }
            }
            "register" -> {
                val clientName = call.argument<String>("clientName")
                val publicKey = call.argument<ByteArray>("publicKey")
                if (clientName == null || publicKey == null) {
                    result.error("INVALID_ARGUMENT", "clientName and publicKey are required", null)
                    return
                }
                try {
                    val clientId = client.register(clientName, publicKey)
                    result.success(clientId)
                } catch (e: Exception) {
                    result.error("REGISTER_ERROR", e.message, null)
                }
            }
            "getPendingChanges" -> {
                val sessionId = call.argument<String>("sessionId")
                val limit = call.argument<Int>("limit")
                if (sessionId == null) {
                    result.error("INVALID_ARGUMENT", "sessionId must not be null", null)
                    return
                }
                try {
                    val pendingJson = client.getPendingChanges(sessionId, limit)
                    result.success(pendingJson)
                } catch (e: Exception) {
                    result.error("PENDING_CHANGES_ERROR", e.message, null)
                }
            }
            "acknowledgeChanges" -> {
                val sessionId = call.argument<String>("sessionId")
                val changeId = call.argument<String>("changeId")
                if (sessionId == null || changeId == null) {
                    result.error("INVALID_ARGUMENT", "sessionId and changeId are required", null)
                    return
                }
                try {
                    val ackJson = client.acknowledgeChanges(sessionId, changeId)
                    result.success(ackJson)
                } catch (e: Exception) {
                    result.error("ACK_ERROR", e.message, null)
                }
            }
            "getClientCursor" -> {
                val sessionId = call.argument<String>("sessionId")
                if (sessionId == null) {
                    result.error("INVALID_ARGUMENT", "sessionId must not be null", null)
                    return
                }
                try {
                    val cursorJson = client.getClientCursor(sessionId)
                    result.success(cursorJson)
                } catch (e: Exception) {
                    result.error("CURSOR_ERROR", e.message, null)
                }
            }
            "isPdsInstalled" -> {
                result.success(client.isPdsInstalled())
            }
            "installPdsApk" -> {
                val apkUriString = call.argument<String>("apkUriString")
                if (apkUriString == null) {
                    result.error("INVALID_ARGUMENT", "apkUriString must not be null", null)
                    return
                }
                result.success(client.installPdsApk(apkUriString))
            }
            "listClients" -> {
                try {
                    result.success(client.listClients())
                } catch (e: Exception) {
                    result.error("LIST_CLIENTS_ERROR", e.message, null)
                }
            }
            "revokeClient" -> {
                val clientId = call.argument<String>("clientId")
                if (clientId == null) {
                    result.error("INVALID_ARGUMENT", "clientId must not be null", null)
                    return
                }
                try {
                    result.success(client.revokeClient(clientId))
                } catch (e: Exception) {
                    result.error("REVOKE_CLIENT_ERROR", e.message, null)
                }
            }
            "removeClient" -> {
                val clientId = call.argument<String>("clientId")
                if (clientId == null) {
                    result.error("INVALID_ARGUMENT", "clientId must not be null", null)
                    return
                }
                try {
                    result.success(client.removeClient(clientId))
                } catch (e: Exception) {
                    result.error("REMOVE_CLIENT_ERROR", e.message, null)
                }
            }
            "requestAuthorization" -> {
                val currentActivity = activity
                if (currentActivity == null) {
                    result.error("NO_ACTIVITY", "Cannot launch authorization dialog without foreground activity", null)
                    return
                }
                if (pendingAuthResult != null) {
                    result.error("ALREADY_REQUESTING", "Another authorization request is already pending", null)
                    return
                }

                val clientName = call.argument<String>("clientName") ?: "Client Application"
                val publicKey = call.argument<ByteArray>("publicKey")
                val permissionsList = call.argument<List<String>>("permissions")
                val permissions = permissionsList?.toTypedArray() ?: arrayOf(
                    "ReadEntities", "WriteEntities", "ReadBlobs", "WriteBlobs", "ReadHistory"
                )

                val intent = PdsAndroidClient.createAuthorizationIntent(
                    clientName = clientName,
                    publicKey = publicKey,
                    permissions = permissions
                )

                pendingAuthResult = result
                try {
                    currentActivity.startActivityForResult(intent, REQUEST_CODE_AUTH)
                } catch (e: Exception) {
                    pendingAuthResult = null
                    result.error("LAUNCH_ERROR", "Failed to launch authorization dialog: ${e.message}", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_AUTH) {
            val result = pendingAuthResult
            pendingAuthResult = null
            if (result == null) return true

            if (resultCode == Activity.RESULT_OK && data != null) {
                val clientId = data.getStringExtra(PdsAndroidClient.RESULT_CLIENT_ID)
                val grantedPermissions = data.getStringArrayExtra(PdsAndroidClient.RESULT_GRANTED_PERMISSIONS)?.toList() ?: emptyList<String>()
                val resMap = HashMap<String, Any?>()
                resMap["status"] = "authorized"
                resMap["clientId"] = clientId
                resMap["grantedPermissions"] = grantedPermissions
                result.success(resMap)
            } else {
                val resMap = HashMap<String, Any?>()
                resMap["status"] = "denied"
                resMap["clientId"] = null
                resMap["grantedPermissions"] = emptyList<String>()
                result.success(resMap)
            }
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val entityType = (arguments as? Map<*, *>)?.get("entityType") as? String ?: "*"
        try {
            pdsClient?.subscribe(entityType, changeListener)
        } catch (_: Exception) {}
    }

    override fun onCancel(arguments: Any?) {
        try {
            pdsClient?.unsubscribe(changeListener)
        } catch (_: Exception) {}
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        pdsClient?.disconnect()
        pdsClient = null
    }
}
