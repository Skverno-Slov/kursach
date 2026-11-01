package com.rtsr.signal.services

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import androidx.core.content.edit
import java.io.File

class TokenManager(context: Context) {
    private val appContext = context.applicationContext
    private val fileName = "secret_shared_prefs"

    private val prefs by lazy {
        try {
            createEncryptedPrefs()
        } catch (_: Exception) {
            deleteAllEncryptedFiles()
            createEncryptedPrefs()
        }
    }

    private fun createEncryptedPrefs() = EncryptedSharedPreferences.create(
        appContext,
        fileName,
        MasterKey.Builder(appContext).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private fun deleteAllEncryptedFiles() {
        try {
            val sharedPrefsDir = File(appContext.filesDir.parent, "shared_prefs")
            if (sharedPrefsDir.exists() && sharedPrefsDir.isDirectory) {
                File(sharedPrefsDir, "$fileName.xml").delete()

                sharedPrefsDir.listFiles()?.forEach { file ->
                    if (file.name.contains("androidx_security_crypto")) {
                        file.delete()
                    }
                }
            }
        } catch (_: Exception) {}
    }

    fun getAccessToken(): String? = prefs.getString("access_token", null)

    fun getRefreshToken(): String? = prefs.getString("refresh_token", null)

    fun saveTokens(accessToken: String?, refreshToken: String?) {
        prefs.edit {
            accessToken?.let { putString("access_token", it) }
            refreshToken?.let { putString("refresh_token", it) }
        }
    }

    fun clearTokens() {
        prefs.edit {
            remove("access_token")
            remove("refresh_token")
        }
    }
}