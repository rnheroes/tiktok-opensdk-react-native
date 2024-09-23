package com.tiktokopensdkreactnative

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.*

import android.content.pm.PackageManager
import com.tiktok.open.sdk.core.appcheck.TikTokAppCheckUtil
import com.tiktok.open.sdk.auth.*
import com.tiktok.open.sdk.share.*
import com.tiktok.open.sdk.auth.utils.PKCEUtils
import java.io.File
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import com.tiktok.open.sdk.auth.AuthApi
import com.tiktok.open.sdk.share.model.MediaContent

class TiktokOpensdkReactNativeModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    private lateinit var authApi: AuthApi
    private lateinit var shareApi: ShareApi

    override fun getName(): String = "TiktokOpensdkReactNative"

    @ReactMethod
    fun login(clientKey: String, redirectUri: String, promise: Promise) {
        val activity = currentActivity ?: run {
            promise.reject("ERROR", "Activity is null")
            return
        }

        authApi = AuthApi(activity)

        val codeVerifier = PKCEUtils.generateCodeVerifier()
        val request = AuthRequest(
            clientKey = clientKey,
            scope = "user.info.basic",
            redirectUri = redirectUri,
            codeVerifier = codeVerifier
        )

        val authMethod = if (isTikTokInstalled()) AuthApi.AuthMethod.TikTokApp else AuthApi.AuthMethod.ChromeTab

        authApi.authorize(
            request = request,
            authMethod = authMethod
        )
    }

    @ReactMethod
    fun handleLoginResult(intentUri: String, redirectUri: String, promise: Promise) {
        val intent = Intent.parseUri(intentUri, 0)
        authApi.getAuthResponseFromIntent(intent, redirectUri)?.let { response ->
            val result = Arguments.createMap().apply {
                putString("authCode", response.authCode)
                putArray("grantedPermissions", Arguments.fromList(listOf(response.grantedPermissions)))
                response.authError?.let { putString("authError", it) }
                response.authErrorDescription?.let { putString("authErrorDescription", it) }
            }
            promise.resolve(result)
        } ?: run {
            promise.reject("ERROR", "Failed to parse auth response")
        }
    }

    @ReactMethod
    fun share(clientKey: String, mediaUrls: ReadableArray, isImage: Boolean, isGreenScreen: Boolean, promise: Promise) {
        val activity = currentActivity ?: run {
            promise.reject("ERROR", "Activity is null")
            return
        }
    
        shareApi = ShareApi(activity)
    
        val contentUris = mediaUrls.toArrayList().map { path ->
            val file = File(path as String)
            FileProvider.getUriForFile(reactApplicationContext, "${reactApplicationContext.packageName}.fileprovider", file)
        }
    
        val mediaPathStrings = contentUris.map { it.toString() }
    
        val mediaContent = MediaContent(
            mediaType = if (isImage) MediaType.IMAGE else MediaType.VIDEO,
            mediaPaths = ArrayList(mediaPathStrings)
        )
    
        val shareFormat = if (isGreenScreen) Format.GREEN_SCREEN else Format.DEFAULT
    
        val request = ShareRequest(
            clientKey = clientKey,
            mediaContent = mediaContent,
            shareFormat = shareFormat,
            packageName = reactApplicationContext.packageName,
            resultActivityFullPath = getMainActivityClassName()
        )
    
        contentUris.forEach { uri ->
            reactApplicationContext.grantUriPermission("com.zhiliaoapp.musically", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            reactApplicationContext.grantUriPermission("com.ss.android.ugc.trill", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    
        shareApi.share(request)
    }

    @ReactMethod
    fun handleShareResult(intentUri: String, promise: Promise) {
        val intent = Intent.parseUri(intentUri, 0)
        shareApi.getShareResponseFromIntent(intent)?.let { response ->
            val result = Arguments.createMap().apply {
                putBoolean("isSuccess", response.isSuccess)
                putInt("errorCode", response.errorCode ?: 0)
                putInt("subErrorCode", response.subErrorCode ?: 0)
                putString("errorMsg", response.errorMsg)
            }
            promise.resolve(result)
        } ?: run {
            promise.reject("ERROR", "Failed to parse share response")
        }
    }

    @ReactMethod
    fun grantUriPermission(uriString: String) {
        val uri = Uri.parse(uriString)
        this.reactApplicationContext.grantUriPermission("com.zhiliaoapp.musically", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        this.reactApplicationContext.grantUriPermission("com.ss.android.ugc.trill", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    private fun isTikTokInstalled(): Boolean {
        val pm = reactApplicationContext.packageManager
        return try {
            pm.getPackageInfo("com.zhiliaoapp.musically", 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun getMainActivityClassName(): String {
        val pm = reactApplicationContext.packageManager
        val packageName = reactApplicationContext.packageName
        val launchIntent = pm.getLaunchIntentForPackage(packageName)
        return launchIntent?.component?.className ?: "${packageName}.MainActivity"
    }
}