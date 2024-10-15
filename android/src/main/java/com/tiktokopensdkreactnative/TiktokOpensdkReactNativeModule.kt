package com.tiktokopensdkreactnative

import com.facebook.react.bridge.*
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File

import com.tiktok.open.sdk.share.ShareApi
import com.tiktok.open.sdk.share.ShareRequest
import com.tiktok.open.sdk.share.Format
import com.tiktok.open.sdk.share.MediaType
import com.tiktok.open.sdk.share.model.MediaContent

class TiktokOpensdkReactNativeModule(reactContext: ReactApplicationContext) : 
    ReactContextBaseJavaModule(reactContext), ActivityEventListener {

    private lateinit var shareApi: ShareApi
    private var sharePromise: Promise? = null
    private var isShareInProgress = false
    private val handler = Handler(Looper.getMainLooper())
    // 30 seconds timeout
    private val SHARE_TIMEOUT = 30000L 

    private val clientKey: String by lazy {
        try {
            val resourceId = reactApplicationContext.resources.getIdentifier("tiktok_client_key", "string", reactApplicationContext.packageName)
            Log.d("TikTokSDK", "tiktok_client_key resource id: $resourceId")
            if (resourceId != 0) {
                reactApplicationContext.getString(resourceId)
            } else {
                Log.e("TikTokSDK", "tiktok_client_key resource not found")
                "DEFAULT_CLIENT_KEY"
            }
        } catch (e: Exception) {
            Log.e("TikTokSDK", "Error retrieving tiktok_client_key: ${e.message}")
            "ERROR_RETRIEVING_KEY"
        }
    }

    init {
        Log.d("TikTokSDK", "TiktokOpensdkReactNativeModule initialized")
        reactContext.addActivityEventListener(this)
    }

    override fun getName(): String = "TiktokOpensdkReactNative"

    @ReactMethod
    fun share(mediaUrls: ReadableArray, isImage: Boolean, isGreenScreen: Boolean, promise: Promise) {
        Log.d("TikTokSDK", "Share method called with clientKey: $clientKey, mediaUrls size: ${mediaUrls.size()}, isImage: $isImage, isGreenScreen: $isGreenScreen")
        
        val activity = currentActivity ?: run {
            Log.e("TikTokSDK", "Activity is null")
            promise.reject("ERROR", "Activity is null")
            return
        }

        shareApi = ShareApi(activity)
        sharePromise = promise
        isShareInProgress = true

        val contentUris = ArrayList<String>()
        
        for (i in 0 until mediaUrls.size()) {
            val path = mediaUrls.getString(i)
            Log.d("TikTokSDK", "Processing media path: $path")
            val file = File(Uri.parse(path).path ?: "")
            
            if (!file.exists()) {
                Log.e("TikTokSDK", "File does not exist: ${file.absolutePath}")
                promise.reject("ERROR", "File does not exist: ${file.absolutePath}")
                return
            }
            
            try {
                val authority = "${reactApplicationContext.packageName}.tiktokopensdkfileprovider"
                val uri = FileProvider.getUriForFile(reactApplicationContext, authority, file)
                contentUris.add(uri.toString())
                Log.d("TikTokSDK", "File URI created: $uri")
                
                reactApplicationContext.grantUriPermission("com.zhiliaoapp.musically", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                reactApplicationContext.grantUriPermission("com.ss.android.ugc.trill", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                Log.d("TikTokSDK", "Permissions granted for URI")
            } catch (e: IllegalArgumentException) {
                Log.e("TikTokSDK", "FileProvider cannot access file: ${file.absolutePath}", e)
                promise.reject("ERROR", "FileProvider cannot access file: ${file.absolutePath}. Error: ${e.message}")
                return
            }
        }

        val mediaContent = MediaContent(
            mediaType = if (isImage) MediaType.IMAGE else MediaType.VIDEO,
            mediaPaths = contentUris
        )

        val shareFormat = if (isGreenScreen) Format.GREEN_SCREEN else Format.DEFAULT

        val request = ShareRequest(
            clientKey = clientKey,
            mediaContent = mediaContent,
            shareFormat = shareFormat,
            packageName = reactApplicationContext.packageName,
            resultActivityFullPath = "${reactApplicationContext.packageName}.MainActivity"
        )

        Log.d("TikTokSDK", "Share request created: $request")

        try {
            val result: Boolean = shareApi.share(request)
            Log.d("TikTokSDK", "ShareApi.share result: $result")
            if (result) {
                Log.d("TikTokSDK", "Share request sent successfully")
                // Set a timeout for the share response
                handler.postDelayed({
                    if (isShareInProgress) {
                        Log.e("TikTokSDK", "Share response timed out")
                        isShareInProgress = false
                        sharePromise?.reject("ERROR", "Share response timed out")
                        sharePromise = null
                    }
                }, SHARE_TIMEOUT)
            } else {
                Log.e("TikTokSDK", "Failed to launch TikTok share")
                isShareInProgress = false
                promise.reject("ERROR", "Failed to launch TikTok share")
            }
        } catch (e: Exception) {
            Log.e("TikTokSDK", "Exception during share", e)
            isShareInProgress = false
            promise.reject("ERROR", "Failed to share: ${e.message}")
        }
    }

    override fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?) {
        Log.d("TikTokSDK", "onActivityResult called: requestCode=$requestCode, resultCode=$resultCode")
        Log.d("TikTokSDK", "Intent data: ${data?.toString()}")
        Log.d("TikTokSDK", "Intent extras: ${data?.extras}")
        
        // We'll handle the response in onNewIntent, so we don't need to do anything here
        // Just cancel the timeout
        handler.removeCallbacksAndMessages(null)
    }

    override fun onNewIntent(intent: Intent?) {
        Log.d("TikTokSDK", "onNewIntent called")
        Log.d("TikTokSDK", "Intent data: ${intent?.toString()}")
        Log.d("TikTokSDK", "Intent extras: ${intent?.extras}")

        if (!isShareInProgress) {
            Log.d("TikTokSDK", "No share in progress, ignoring new intent")
            return
        }

        isShareInProgress = false

        try {
            val response = shareApi.getShareResponseFromIntent(intent)
            if (response != null) {
                Log.d("TikTokSDK", "Share response in onNewIntent: isSuccess=${response.isSuccess}, errorCode=${response.errorCode}, errorMsg=${response.errorMsg}")
                val result = Arguments.createMap().apply {
                    putBoolean("isSuccess", response.isSuccess)
                    putInt("errorCode", response.errorCode ?: 0)
                    putInt("subErrorCode", response.errorCode ?: 0)
                    putString("errorMsg", response.errorMsg)
                }
                sharePromise?.resolve(result)
            } else {
                Log.e("TikTokSDK", "Failed to get share response from intent in onNewIntent")
                sharePromise?.reject("ERROR", "Failed to get share response")
            }
        } catch (e: Exception) {
            Log.e("TikTokSDK", "Exception in onNewIntent", e)
            sharePromise?.reject("ERROR", "Exception in onNewIntent: ${e.message}")
        } finally {
            sharePromise = null
        }
    }

    private fun processShareResult(data: Intent?) {
        isShareInProgress = false
        handler.removeCallbacksAndMessages(null)
    
        if (sharePromise == null) {
            Log.e("TikTokSDK", "sharePromise is null in processShareResult")
            return
        }
    
        try {
            val response = shareApi.getShareResponseFromIntent(data)
            if (response != null) {
                Log.d("TikTokSDK", "Share response: isSuccess=${response.isSuccess}, errorCode=${response.errorCode}, errorMsg=${response.errorMsg}")
                val result = Arguments.createMap().apply {
                    putBoolean("isSuccess", response.isSuccess)
                    putInt("errorCode", response.errorCode ?: 0)
                    putString("errorMsg", response.errorMsg)
                }
                sharePromise?.resolve(result)
            } else {
                Log.e("TikTokSDK", "Failed to get share response from intent")
                sharePromise?.reject("ERROR", "Failed to get share response")
            }
        } catch (e: Exception) {
            Log.e("TikTokSDK", "Exception in processShareResult", e)
            sharePromise?.reject("ERROR", "Exception in processShareResult: ${e.message}")
        } finally {
            sharePromise = null
        }
    }
}