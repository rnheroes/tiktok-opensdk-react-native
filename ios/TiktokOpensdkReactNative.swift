import Foundation
import TikTokOpenSDKCore
import TikTokOpenShareSDK
import Photos

@objc(TiktokOpensdkReactNative)
public class TiktokOpensdkReactNative: NSObject {
    private static var pendingResolver: RCTPromiseResolveBlock?
    private static var pendingRejecter: RCTPromiseRejectBlock?
    private var downloadGroup: DispatchGroup?
    
    @objc static func getRedirectURI() -> String? {
        guard let redirectURI = Bundle.main.object(forInfoDictionaryKey: "TikTokClientKey") as? String else {
            return nil
        }
        return "\(redirectURI)://"
    }
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    @objc func share(_ mediaUrls: [String], isImage: Bool, isGreenScreen: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        NSLog("TikTok SDK: Share function called")
        
        // Ensure we're starting fresh
        downloadGroup = DispatchGroup()
        
        DispatchQueue.main.async { [weak self] in
            self?.downloadAndShareMedia(mediaUrls: mediaUrls, isImage: isImage, isGreenScreen: isGreenScreen, resolver: resolver, rejecter: rejecter)
        }
    }
    
    private func downloadAndShareMedia(mediaUrls: [String], isImage: Bool, isGreenScreen: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        NSLog("TikTok SDK: Preparing media for sharing")
        guard let downloadGroup = downloadGroup else {
            rejecter("INTERNAL_ERROR", "Download group not initialized", nil)
            return
        }
        
        var localIdentifiers: [String] = []
        let synchronizationQueue = DispatchQueue(label: "com.tiktok.sdk.sync")
        
        for urlString in mediaUrls {
            downloadGroup.enter()
            
            guard let url = URL(string: urlString) else {
                NSLog("TikTok SDK: Invalid media URL: \(urlString)")
                downloadGroup.leave()
                continue
            }
            
            downloadMedia(from: url, isImage: isImage) { [weak self] identifier in
                synchronizationQueue.async {
                    if let identifier = identifier {
                        localIdentifiers.append(identifier)
                    }
                    downloadGroup.leave()
                }
            }
        }
        
        downloadGroup.notify(queue: .main) { [weak self] in
            if localIdentifiers.isEmpty {
                NSLog("TikTok SDK: No media saved successfully")
                rejecter("SAVE_ERROR", "Failed to save media", nil)
                return
            }
            self?.performTikTokShare(localIdentifiers: localIdentifiers, isImage: isImage, isGreenScreen: isGreenScreen, resolver: resolver, rejecter: rejecter)
        }
    }
    
    private func downloadMedia(from url: URL, isImage: Bool, completion: @escaping (String?) -> Void) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaURL = %@", url as CVarArg)
        
        // First check if the asset already exists
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        if let existingAsset = fetchResult.firstObject {
            completion(existingAsset.localIdentifier)
            return
        }
        
        // If not found, download and save
        URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    NSLog("TikTok SDK: Error downloading media: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                let assetCreationRequest = PHAssetCreationRequest.forAsset()
                if isImage {
                    assetCreationRequest.addResource(with: .photo, fileURL: tempURL, options: nil)
                } else {
                    assetCreationRequest.addResource(with: .video, fileURL: tempURL, options: nil)
                }
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        NSLog("TikTok SDK: Media saved successfully")
                        // Fetch the saved asset's identifier
                        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
                        if let asset = fetchResult.firstObject {
                            completion(asset.localIdentifier)
                        } else {
                            completion(nil)
                        }
                    } else {
                        NSLog("TikTok SDK: Error saving media: \(error?.localizedDescription ?? "Unknown error")")
                        completion(nil)
                    }
                }
            }
        }.resume()
    }
    
    private func performTikTokShare(localIdentifiers: [String], isImage: Bool, isGreenScreen: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        NSLog("TikTok SDK: Performing TikTok share")
        let mediaType: TikTokShareMediaType = isImage ? .image : .video

        guard let redirectURI = TiktokOpensdkReactNative.getRedirectURI() else {
            NSLog("TikTok SDK: Failed to get redirect URI")
            rejecter("REDIRECT_URI_ERROR", "Failed to get redirect URI", nil)
            return
        }

        NSLog("TikTok SDK: Redirect URI: \(redirectURI)")
        
        let shareRequest = TikTokShareRequest(localIdentifiers: localIdentifiers,
                                              mediaType: mediaType,
                                              redirectURI: redirectURI)
        
        if isGreenScreen {
            shareRequest.shareFormat = TikTokShareFormatType.greenScreen
        } else {
            shareRequest.shareFormat = TikTokShareFormatType.normal
        }

        NSLog("TikTok SDK: Sending share request")
        shareRequest.send(nil)
        
        TiktokOpensdkReactNative.pendingResolver = resolver
        TiktokOpensdkReactNative.pendingRejecter = rejecter
    }

    @objc public static func handleOpenURL(_ url: URL) -> Bool {
        NSLog("TikTok SDK: Handling open URL")
        
        guard let redirectURI = TiktokOpensdkReactNative.getRedirectURI() else {
            NSLog("TikTok SDK: Failed to get redirect URI")
            //TODO: We can't use pendingRejecter here as it's not accessible in a static context
            return false
        }

        do {
            let shareResponse = try TikTokShareResponse(fromURL: url, redirectURI: redirectURI)
            
            NSLog("TikTok SDK: Share response received - Error Code: \(shareResponse.errorCode.rawValue), Share State: \(shareResponse.shareState.rawValue)")
            
            if shareResponse.errorCode == .noError {
                NSLog("TikTok SDK: Share succeeded")
                pendingResolver?(["isSuccess": true])
            } else {
                NSLog("TikTok SDK: Share failed - \(shareResponse.errorDescription ?? "Unknown error")")
                let errorInfo: [String: Any] = [
                    "isSuccess": false,
                    "errorCode": shareResponse.errorCode.rawValue,
                    "errorMsg": shareResponse.errorDescription ?? "Unknown error",
                    "shareState": shareResponse.shareState.rawValue
                ]
                pendingResolver?(errorInfo)
            }
        } catch {
            NSLog("TikTok SDK: Error creating share response - \(error.localizedDescription)")
            pendingRejecter?("SHARE_RESPONSE_ERROR", "Failed to create share response", error)
        }
        
        pendingResolver = nil
        pendingRejecter = nil
        
        return true
    }

    @objc public static func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            return handleOpenURL(url)
        }
        return false
    }
}