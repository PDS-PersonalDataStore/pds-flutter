package top.tau2c.pds.client

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import top.tau2c.pds.core.IPdsChangeListener
import top.tau2c.pds.core.IPdsService
import java.util.concurrent.CopyOnWriteArrayList

/**
 * High-level Android SDK client for integrating with the central PDS Core background service.
 */
class PdsAndroidClient(private val context: Context) {

    companion object {
        const val PDS_SERVICE_ACTION = "top.tau2c.pds.core.PDS_SERVICE"
        const val PDS_PACKAGE_NAME = "top.tau2c.pds.core"

        const val ACTION_REQUEST_AUTHORIZATION = "top.tau2c.pds.core.REQUEST_AUTHORIZATION"
        const val EXTRA_CLIENT_NAME = "client_name"
        const val EXTRA_PUBLIC_KEY = "public_key"
        const val EXTRA_PERMISSIONS = "permissions"

        const val RESULT_CLIENT_ID = "client_id"
        const val RESULT_GRANTED_PERMISSIONS = "granted_permissions"

        /**
         * Creates an Intent to launch the interactive PDS Core authorization popup dialog.
         */
        fun createAuthorizationIntent(
            clientName: String,
            publicKey: ByteArray? = null,
            permissions: Array<String> = arrayOf("ReadEntities", "WriteEntities", "ReadBlobs", "WriteBlobs", "ReadHistory")
        ): Intent {
            return Intent(ACTION_REQUEST_AUTHORIZATION).apply {
                setPackage(PDS_PACKAGE_NAME)
                putExtra(EXTRA_CLIENT_NAME, clientName)
                if (publicKey != null) {
                    putExtra(EXTRA_PUBLIC_KEY, publicKey)
                }
                putExtra(EXTRA_PERMISSIONS, permissions)
            }
        }

        /**
         * Context-aware helper creating authorization intent with automatically derived identity public key.
         */
        fun createAuthorizationIntent(
            context: Context,
            clientName: String,
            permissions: Array<String> = arrayOf("ReadEntities", "WriteEntities", "ReadBlobs", "WriteBlobs", "ReadHistory")
        ): Intent {
            val pubKey = PdsCryptoManager.getOrCreateIdentityPublicKey(context)
            return createAuthorizationIntent(clientName, pubKey, permissions)
        }
    }

    private var pdsService: IPdsService? = null
    private var isBound = false

    fun interface ChangeListener {
        fun onChanges(changeEventsJson: String)
    }

    private class ListenerEntry(
        val listener: ChangeListener,
        val filterJson: String,
        val aidlCallback: IPdsChangeListener.Stub
    )

    private val activeSubscriptions = CopyOnWriteArrayList<ListenerEntry>()

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            pdsService = IPdsService.Stub.asInterface(service)
            isBound = true

            // Re-register active subscriptions after reconnect
            activeSubscriptions.forEach { entry ->
                try {
                    pdsService?.registerChangeListener(entry.filterJson, entry.aidlCallback)
                } catch (_: Exception) {}
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            pdsService = null
            isBound = false
        }
    }

    /**
     * Binds to the background PDS Core service.
     */
    fun connect(): Boolean {
        val intent = Intent(PDS_SERVICE_ACTION).apply {
            setPackage(PDS_PACKAGE_NAME)
        }
        isBound = context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
        return isBound
    }

    /**
     * Unbinds from the PDS Core service.
     */
    fun disconnect() {
        if (isBound) {
            activeSubscriptions.forEach { entry ->
                try {
                    pdsService?.unregisterChangeListener(entry.aidlCallback)
                } catch (_: Exception) {}
            }
            context.unbindService(serviceConnection)
            isBound = false
            pdsService = null
        }
    }

    fun isConnected(): Boolean {
        return isBound && pdsService != null
    }

    /**
     * Sends a raw JSON request to PDS and returns the raw JSON response.
     */
    fun executeRawRequest(requestJson: String): String {
        val service = pdsService ?: throw IllegalStateException("PdsService is not connected")
        return service.executeRequest(requestJson)
    }

    /**
     * Creates an Intent to launch the interactive PDS Core authorization popup dialog using this client's identity key.
     */
    fun createAuthorizationIntent(
        clientName: String,
        permissions: Array<String> = arrayOf("ReadEntities", "WriteEntities", "ReadBlobs", "WriteBlobs", "ReadHistory")
    ): Intent {
        return createAuthorizationIntent(context, clientName, permissions)
    }

    /**
     * Handles the result Intent from the authorization Activity, storing the clientId if authorization succeeded.
     * Returns the authorized clientId, or null if cancelled or missing.
     */
    fun handleAuthResult(resultIntent: Intent?): String? {
        val clientId = resultIntent?.getStringExtra(RESULT_CLIENT_ID)
        if (!clientId.isNullOrEmpty()) {
            saveClientId(clientId)
        }
        return clientId
    }

    /**
     * Retrieves the stored registered client identifier, or null if not yet authorized.
     */
    fun getClientId(): String? {
        return PdsCryptoManager.getClientId(context)
    }

    /**
     * Persists the registered client identifier.
     */
    fun saveClientId(clientId: String) {
        PdsCryptoManager.saveClientId(context, clientId)
    }

    /**
     * Checks if this client has an authorized clientId stored locally.
     */
    fun isAuthorized(): Boolean {
        return !getClientId().isNullOrEmpty()
    }

    /**
     * Clears stored client identity and authorization details.
     */
    fun clearClientIdentity() {
        PdsCryptoManager.clearClientIdentity(context)
    }

    /**
     * Registers this client application with the provided or automatically derived public key.
     */
    fun register(clientName: String, publicKey: ByteArray? = null): String {
        val service = pdsService ?: throw IllegalStateException("PdsService is not connected")
        val key = publicKey ?: PdsCryptoManager.getOrCreateIdentityPublicKey(context)
        val id = service.registerClient(clientName, key)
        if (id.isNotEmpty()) {
            saveClientId(id)
        }
        return id
    }

    /**
     * Checks if PDS storage engine is ready.
     */
    fun isReady(): Boolean {
        return pdsService?.isReady ?: false
    }

    /**
     * Subscribes to real-time storage changes.
     * @param entityType Specific entity type to watch, or "*" for all entities.
     * @param listener Callback invoked when changes occur.
     */
    fun subscribe(entityType: String = "*", listener: ChangeListener) {
        val service = pdsService ?: throw IllegalStateException("PdsService is not connected")
        val filterJson = """{"entity_type":"$entityType"}"""
        val callback = object : IPdsChangeListener.Stub() {
            override fun onChanges(changeEventsJson: String?) {
                if (changeEventsJson != null) {
                    listener.onChanges(changeEventsJson)
                }
            }
        }
        val entry = ListenerEntry(listener, filterJson, callback)
        activeSubscriptions.add(entry)
        service.registerChangeListener(filterJson, callback)
    }

    /**
     * Unsubscribes a previously registered listener.
     */
    fun unsubscribe(listener: ChangeListener) {
        val entry = activeSubscriptions.firstOrNull { it.listener == listener } ?: return
        activeSubscriptions.remove(entry)
        try {
            pdsService?.unregisterChangeListener(entry.aidlCallback)
        } catch (_: Exception) {}
    }

    /**
     * Retrieves pending changes for an offline/reconnecting client session.
     */
    fun getPendingChanges(sessionId: String, limit: Int? = null): String {
        val limitJson = if (limit != null) ""","limit":$limit""" else ""
        val req = """{"action":"get_pending_changes","session_id":"$sessionId"$limitJson}"""
        return executeRawRequest(req)
    }

    /**
     * Acknowledges processed changes and advances durable client cursor.
     */
    fun acknowledgeChanges(sessionId: String, changeId: String): String {
        val req = """{"action":"acknowledge_changes","session_id":"$sessionId","change_id":"$changeId"}"""
        return executeRawRequest(req)
    }

    /**
     * Reads durable client cursor position.
     */
    fun getClientCursor(sessionId: String): String {
        val req = """{"action":"get_client_cursor","session_id":"$sessionId"}"""
        return executeRawRequest(req)
    }

    /**
     * Creates a binary relation between source and target entities.
     */
    fun createRelation(
        sessionId: String,
        relationType: String,
        sourceEntityId: String,
        targetEntityId: String
    ): String {
        val req = """{"action":"create_relation","session_id":"$sessionId","relation_type":"$relationType","source":"$sourceEntityId","target":"$targetEntityId"}"""
        return executeRawRequest(req)
    }

    /**
     * Creates a multimember relation with custom roles (Engine 1.5).
     * @param membersJson JSON array of members, e.g. '[{"entity_id":"...","role":"author"}]'
     */
    fun createMultimemberRelation(
        sessionId: String,
        relationType: String,
        membersJson: String
    ): String {
        val req = """{"action":"create_relation","session_id":"$sessionId","relation_type":"$relationType","members":$membersJson}"""
        return executeRawRequest(req)
    }

    /**
     * Stores raw binary data as a content-addressed blob.
     * Returns the PDS JSON response containing the BlobDescriptor.
     */
    fun putBlob(sessionId: String, data: ByteArray, mediaType: String? = null): String {
        val mediaTypeJson = if (mediaType != null) ""","media_type":"$mediaType"""" else ""
        val dataArrayJson = data.joinToString(prefix = "[", postfix = "]", separator = ",") { (it.toInt() and 0xFF).toString() }
        val req = """{"action":"put_blob","session_id":"$sessionId","data":$dataArrayJson$mediaTypeJson}"""
        return executeRawRequest(req)
    }

    /**
     * Retrieves raw binary data by blob ID.
     * Returns the byte array of the blob.
     */
    fun getBlob(sessionId: String, blobId: String): ByteArray {
        val req = """{"action":"get_blob","session_id":"$sessionId","blob_id":"$blobId"}"""
        val responseJson = executeRawRequest(req)
        val json = org.json.JSONObject(responseJson)
        if (json.has("status") && json.getString("status") == "Error") {
            throw java.io.IOException("Failed to get blob: ${json.optString("payload")}")
        }
        val payloadArray = json.getJSONArray("payload")
        val bytes = ByteArray(payloadArray.length())
        for (i in 0 until payloadArray.length()) {
            bytes[i] = payloadArray.getInt(i).toByte()
        }
        return bytes
    }

    /**
     * Encrypts plaintext data using client-side AES-256-GCM via AndroidKeyStore
     * and stores the ciphertext as a blob in PDS Core (Zero-Knowledge E2EE).
     */
    fun putEncryptedBlob(
        sessionId: String,
        plaintext: ByteArray,
        keyAlias: String,
        mediaType: String? = "application/octet-stream"
    ): String {
        val encryptedData = PdsCryptoManager.encrypt(plaintext, keyAlias)
        return putBlob(sessionId, encryptedData, mediaType)
    }

    /**
     * Retrieves an encrypted blob from PDS Core and decrypts it client-side
     * using the specified AndroidKeyStore key alias.
     */
    fun getEncryptedBlob(
        sessionId: String,
        blobId: String,
        keyAlias: String
    ): ByteArray {
        val encryptedBytes = getBlob(sessionId, blobId)
        return PdsCryptoManager.decrypt(encryptedBytes, keyAlias)
    }

    /**
     * Returns JSON list of all registered client applications.
     */
    fun listClients(): String {
        val service = pdsService ?: throw IllegalStateException("PDS service is not connected")
        return service.listClients() ?: "[]"
    }

    /**
     * Revokes permissions of a client application.
     */
    fun revokeClient(clientId: String): Boolean {
        val service = pdsService ?: throw IllegalStateException("PDS service is not connected")
        return service.revokeClient(clientId)
    }

    /**
     * Removes a client application record completely.
     */
    fun removeClient(clientId: String): Boolean {
        val service = pdsService ?: throw IllegalStateException("PDS service is not connected")
        return service.removeClient(clientId)
    }

    /**
     * Configures the tracing log level filter dynamically on PDS Core.
     * @param logLevel Filter string (e.g. "info", "debug", "trace", "pds=debug").
     */
    fun setLogLevel(logLevel: String): Boolean {
        val service = pdsService ?: throw IllegalStateException("PDS service is not connected")
        return service.setLogLevel(logLevel)
    }

    /**
     * Retrieves current tracing log level filter from PDS Core.
     */
    fun getLogLevel(): String {
        val service = pdsService ?: throw IllegalStateException("PDS service is not connected")
        return service.logLevel ?: ""
    }

    /**
     * Checks if PDS Core package is installed on the device.
     */
    fun isPdsInstalled(): Boolean {
        return try {
            context.packageManager.getPackageInfo(PDS_PACKAGE_NAME, 0)
            true
        } catch (_: Exception) {
            false
        }
    }

    fun installPdsApk(apkUriString: String): Boolean {
        return try {
            val uri = android.net.Uri.parse(apkUriString)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
