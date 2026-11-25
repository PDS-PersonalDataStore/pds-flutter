package top.tau2c.pds.client

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Client-side cryptographic manager for End-to-End Encryption (E2EE) / Zero-Knowledge storage.
 * Manages AES-256-GCM symmetric keys backed by the hardware AndroidKeyStore provider.
 */
object PdsCryptoManager {

    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val AES_GCM_TRANSFORMATION = "AES/GCM/NoPadding"
    private const val GCM_IV_LENGTH = 12
    private const val GCM_TAG_LENGTH = 128

    /**
     * Gets an existing AES key or generates a new one in the Android Keystore.
     */
    fun getOrCreateKey(keyAlias: String): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        if (keyStore.containsAlias(keyAlias)) {
            val entry = keyStore.getEntry(keyAlias, null) as? KeyStore.SecretKeyEntry
            if (entry != null) {
                return entry.secretKey
            }
        }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )
        val spec = KeyGenParameterSpec.Builder(
            keyAlias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build()

        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }

    /**
     * Encrypts plaintext bytes using AES-256-GCM.
     * The resulting byte array prepends the 12-byte IV followed by the ciphertext + authentication tag.
     */
    fun encrypt(plaintext: ByteArray, keyAlias: String): ByteArray {
        val secretKey = getOrCreateKey(keyAlias)
        val cipher = Cipher.getInstance(AES_GCM_TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        val iv = cipher.iv // 12 bytes
        val ciphertext = cipher.doFinal(plaintext)
        return iv + ciphertext
    }

    /**
     * Decrypts an encrypted payload (12-byte IV + ciphertext + authentication tag) using AES-256-GCM.
     */
    fun decrypt(encryptedPayload: ByteArray, keyAlias: String): ByteArray {
        require(encryptedPayload.size > GCM_IV_LENGTH) { "Ciphertext too short" }
        val secretKey = getOrCreateKey(keyAlias)
        val iv = encryptedPayload.copyOfRange(0, GCM_IV_LENGTH)
        val ciphertext = encryptedPayload.copyOfRange(GCM_IV_LENGTH, encryptedPayload.size)

        val cipher = Cipher.getInstance(AES_GCM_TRANSFORMATION)
        val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
        return cipher.doFinal(ciphertext)
    }

    private const val PREFS_NAME = "pds_client_identity"
    private const val KEY_CLIENT_ID = "pds_client_id"
    private const val KEY_PRIVATE_KEY = "pds_private_key"
    private const val KEY_PUBLIC_KEY = "pds_public_key"

    /**
     * Gets or creates a 32-byte Ed25519-compatible identity private seed in private storage,
     * encrypted with a master key from AndroidKeyStore.
     */
    @Synchronized
    fun getOrCreateIdentityPrivateKey(context: android.content.Context): ByteArray {
        val prefs = context.getSharedPreferences(PREFS_NAME, android.content.Context.MODE_PRIVATE)
        val encryptedHex = prefs.getString(KEY_PRIVATE_KEY, null)
        if (encryptedHex != null) {
            val encryptedBytes = hexToBytes(encryptedHex)
            return decrypt(encryptedBytes, "pds_identity_master_key")
        }

        // Generate 32 bytes cryptographically secure random private seed
        val privateKey = ByteArray(32).apply {
            java.security.SecureRandom().nextBytes(this)
        }

        val encryptedBytes = encrypt(privateKey, "pds_identity_master_key")
        prefs.edit().putString(KEY_PRIVATE_KEY, bytesToHex(encryptedBytes)).apply()

        // Derive and store public key
        val publicKey = derivePublicKeyFromSeed(privateKey)
        prefs.edit().putString(KEY_PUBLIC_KEY, bytesToHex(publicKey)).apply()

        return privateKey
    }

    /**
     * Retrieves the 32-byte public key corresponding to the client identity key.
     */
    @Synchronized
    fun getOrCreateIdentityPublicKey(context: android.content.Context): ByteArray {
        val prefs = context.getSharedPreferences(PREFS_NAME, android.content.Context.MODE_PRIVATE)
        val pubHex = prefs.getString(KEY_PUBLIC_KEY, null)
        if (pubHex != null) {
            return hexToBytes(pubHex)
        }
        val privKey = getOrCreateIdentityPrivateKey(context)
        val pubKey = derivePublicKeyFromSeed(privKey)
        prefs.edit().putString(KEY_PUBLIC_KEY, bytesToHex(pubKey)).apply()
        return pubKey
    }

    /**
     * Stores the registered clientId returned from PDS authorization.
     */
    fun saveClientId(context: android.content.Context, clientId: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, android.content.Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_CLIENT_ID, clientId).apply()
    }

    /**
     * Returns the stored clientId, or null if not yet authorized.
     */
    fun getClientId(context: android.content.Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, android.content.Context.MODE_PRIVATE)
        return prefs.getString(KEY_CLIENT_ID, null)
    }

    /**
     * Clears stored client authorization details.
     */
    fun clearClientIdentity(context: android.content.Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, android.content.Context.MODE_PRIVATE)
        prefs.edit().clear().apply()
    }

    private fun derivePublicKeyFromSeed(seed: ByteArray): ByteArray {
        // Derive Ed25519 public key from 32-byte private seed using SHA-512 clamp & Edwards point scalar mul
        val md = java.security.MessageDigest.getInstance("SHA-512")
        val h = md.digest(seed)
        h[0] = (h[0].toInt() and 248).toByte()
        h[31] = (h[31].toInt() and 127).toByte()
        h[31] = (h[31].toInt() or 64).toByte()

        val a = java.math.BigInteger(1, h.copyOfRange(0, 32).reversedArray())
        val p = java.math.BigInteger.valueOf(2).pow(255).subtract(java.math.BigInteger.valueOf(19))
        val d = java.math.BigInteger("-121665").multiply(java.math.BigInteger("121666").modInverse(p)).mod(p)
        val bx = java.math.BigInteger("1511222134953540077250115140958853151145401269304185720604611328326514776390")
        val by = java.math.BigInteger("46316835694926478169428394003475163141307993866256225615783033603165251855960")

        fun edwardsAdd(p1: Pair<java.math.BigInteger, java.math.BigInteger>, p2: Pair<java.math.BigInteger, java.math.BigInteger>): Pair<java.math.BigInteger, java.math.BigInteger> {
            val (x1, y1) = p1
            val (x2, y2) = p2
            val numX = x1.multiply(y2).add(y1.multiply(x2)).mod(p)
            val denX = java.math.BigInteger.ONE.add(d.multiply(x1).multiply(x2).multiply(y1).multiply(y2)).mod(p)
            val numY = y1.multiply(y2).add(x1.multiply(x2)).mod(p)
            val denY = java.math.BigInteger.ONE.subtract(d.multiply(x1).multiply(x2).multiply(y1).multiply(y2)).mod(p)
            return Pair(numX.multiply(denX.modInverse(p)).mod(p), numY.multiply(denY.modInverse(p)).mod(p))
        }

        var r = Pair(java.math.BigInteger.ZERO, java.math.BigInteger.ONE)
        var q = Pair(bx, by)
        for (i in 0 until 256) {
            if (a.testBit(i)) {
                r = edwardsAdd(r, q)
            }
            q = edwardsAdd(q, q)
        }

        // Encode point Y with sign bit of X in MSB of last byte
        val yBytes = r.second.toByteArray().reversedArray()
        val pub = ByteArray(32)
        System.arraycopy(yBytes, 0, pub, 0, minOf(yBytes.size, 32))
        if (r.first.testBit(0)) {
            pub[31] = (pub[31].toInt() or 0x80).toByte()
        }
        return pub
    }

    private fun bytesToHex(bytes: ByteArray): String {
        val hexChars = "0123456789abcdef"
        val result = StringBuilder(bytes.size * 2)
        for (b in bytes) {
            val i = b.toInt() and 0xFF
            result.append(hexChars[i shr 4])
            result.append(hexChars[i and 0x0F])
        }
        return result.toString()
    }

    private fun hexToBytes(hex: String): ByteArray {
        val len = hex.length
        val data = ByteArray(len / 2)
        for (i in 0 until len step 2) {
            data[i / 2] = ((Character.digit(hex[i], 16) shl 4) + Character.digit(hex[i + 1], 16)).toByte()
        }
        return data
    }
}
