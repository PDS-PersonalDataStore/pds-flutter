package top.tau2c.pds.flutter.pds_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry
import top.tau2c.pds.client.PdsAndroidClient

/**
 * Android implementation of the PDS Flutter plugin bridging Flutter to PdsAndroidClient
 * via Pigeon-generated typed host API and EventChannel for reactive streams.
 */
class PdsFlutterPlugin : FlutterPlugin, PdsHostApi, EventChannel.StreamHandler, ActivityAware, PluginRegistry.ActivityResultListener {

    companion object {
        private const val REQUEST_CODE_AUTH = 4284
    }

    private lateinit var eventChannel: EventChannel
    private lateinit var binaryMessenger: BinaryMessenger
    private lateinit var context: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingAuthCallback: ((Result<PdsAuthResultDto>) -> Unit)? = null
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
        binaryMessenger = flutterPluginBinding.binaryMessenger
        pdsClient = PdsAndroidClient(context)

        PdsHostApi.setUp(binaryMessenger, this)

        eventChannel = EventChannel(binaryMessenger, "top.tau2c.pds/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PdsHostApi.setUp(binaryMessenger, null)
        eventChannel.setStreamHandler(null)
        pdsClient?.disconnect()
        pdsClient = null
    }

    // PdsHostApi Implementation

    override fun connect(callback: (Result<Boolean>) -> Unit) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val connected = client.connect()
            callback(Result.success(connected))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun disconnect(): Boolean {
        pdsClient?.disconnect()
        return true
    }

    override fun isConnected(): Boolean {
        return pdsClient?.isConnected() ?: false
    }

    override fun isReady(): Boolean {
        return pdsClient?.isReady() ?: false
    }

    override fun executeRawRequest(requestJson: String, callback: (Result<String>) -> Unit) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val response = client.executeRawRequest(requestJson)
            callback(Result.success(response))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun registerClient(clientName: String, publicKey: ByteArray?, callback: (Result<String>) -> Unit) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val clientId = client.register(clientName, publicKey)
            callback(Result.success(clientId))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun getClientId(): String? {
        return pdsClient?.getClientId()
    }

    override fun isAuthorized(): Boolean {
        return pdsClient?.isAuthorized() ?: false
    }

    override fun clearClientIdentity() {
        pdsClient?.clearClientIdentity()
    }

    override fun getPendingChanges(sessionId: String, limit: Long?, callback: (Result<String>) -> Unit) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val pendingJson = client.getPendingChanges(sessionId, limit?.toInt())
            callback(Result.success(pendingJson))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun acknowledgeChanges(sessionId: String, changeId: String, callback: (Result<String>) -> Unit) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val ackJson = client.acknowledgeChanges(sessionId, changeId)
            callback(Result.success(ackJson))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun getClientCursor(sessionId: String, callback: (Result<String>) -> Unit) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val cursorJson = client.getClientCursor(sessionId)
            callback(Result.success(cursorJson))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun createRelation(
        sessionId: String,
        relationType: String,
        sourceEntityId: String,
        targetEntityId: String,
        callback: (Result<String>) -> Unit
    ) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val resJson = client.createRelation(sessionId, relationType, sourceEntityId, targetEntityId)
            callback(Result.success(resJson))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun createMultimemberRelation(
        sessionId: String,
        relationType: String,
        membersJson: String,
        callback: (Result<String>) -> Unit
    ) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val resJson = client.createMultimemberRelation(sessionId, relationType, membersJson)
            callback(Result.success(resJson))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun putBlob(
        sessionId: String,
        data: ByteArray,
        mediaType: String?,
        callback: (Result<String>) -> Unit
    ) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val resJson = client.putBlob(sessionId, data, mediaType)
            callback(Result.success(resJson))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun getBlob(sessionId: String, blobId: String, callback: (Result<ByteArray>) -> Unit) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val bytes = client.getBlob(sessionId, blobId)
            callback(Result.success(bytes))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun putEncryptedBlob(
        sessionId: String,
        plaintext: ByteArray,
        keyAlias: String,
        mediaType: String?,
        callback: (Result<String>) -> Unit
    ) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val resJson = client.putEncryptedBlob(sessionId, plaintext, keyAlias, mediaType ?: "application/octet-stream")
            callback(Result.success(resJson))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun getEncryptedBlob(
        sessionId: String,
        blobId: String,
        keyAlias: String,
        callback: (Result<ByteArray>) -> Unit
    ) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val bytes = client.getEncryptedBlob(sessionId, blobId, keyAlias)
            callback(Result.success(bytes))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun isPdsInstalled(): Boolean {
        return pdsClient?.isPdsInstalled() ?: false
    }

    override fun installPdsApk(apkUriString: String): Boolean {
        return pdsClient?.installPdsApk(apkUriString) ?: false
    }

    override fun listClients(): String {
        return pdsClient?.listClients() ?: "[]"
    }

    override fun revokeClient(clientId: String): Boolean {
        return pdsClient?.revokeClient(clientId) ?: false
    }

    override fun removeClient(clientId: String): Boolean {
        return pdsClient?.removeClient(clientId) ?: false
    }

    override fun setLogLevel(logLevel: String, callback: (Result<Boolean>) -> Unit) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val success = client.setLogLevel(logLevel)
            callback(Result.success(success))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun getLogLevel(callback: (Result<String>) -> Unit) {
        val client = pdsClient ?: run {
            callback(Result.failure(IllegalStateException("PDS Client is not initialized")))
            return
        }
        try {
            val level = client.getLogLevel()
            callback(Result.success(level))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun requestAuthorization(
        clientName: String,
        publicKey: ByteArray?,
        permissions: List<String>?,
        callback: (Result<PdsAuthResultDto>) -> Unit
    ) {
        val currentActivity = activity
        if (currentActivity == null) {
            callback(Result.failure(IllegalStateException("Cannot launch authorization dialog without foreground activity")))
            return
        }
        if (pendingAuthCallback != null) {
            callback(Result.failure(IllegalStateException("Another authorization request is already pending")))
            return
        }

        val perms = permissions?.toTypedArray() ?: arrayOf(
            "ReadEntities", "WriteEntities", "ReadBlobs", "WriteBlobs", "ReadHistory"
        )

        val intent = PdsAndroidClient.createAuthorizationIntent(
            clientName = clientName,
            publicKey = publicKey,
            permissions = perms
        )

        pendingAuthCallback = callback
        try {
            currentActivity.startActivityForResult(intent, REQUEST_CODE_AUTH)
        } catch (e: Exception) {
            pendingAuthCallback = null
            callback(Result.failure(e))
        }
    }

    // ActivityAware & ActivityResultListener

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_AUTH) {
            val callback = pendingAuthCallback
            pendingAuthCallback = null
            if (callback == null) return true

            if (resultCode == Activity.RESULT_OK && data != null) {
                val clientId = pdsClient?.handleAuthResult(data) ?: data.getStringExtra(PdsAndroidClient.RESULT_CLIENT_ID)
                val grantedPermissions = data.getStringArrayExtra(PdsAndroidClient.RESULT_GRANTED_PERMISSIONS)?.toList() ?: emptyList<String>()
                callback(Result.success(PdsAuthResultDto(
                    isAuthorized = true,
                    clientId = clientId,
                    grantedPermissions = grantedPermissions
                )))
            } else {
                callback(Result.success(PdsAuthResultDto(
                    isAuthorized = false,
                    clientId = null,
                    grantedPermissions = emptyList()
                )))
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

    // StreamHandler for watchChanges

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
}
