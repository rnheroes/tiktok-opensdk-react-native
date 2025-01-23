import Foundation
import TikTokOpenSDKCore
import TikTokOpenShareSDK
import Photos

@objc(TiktokOpensdkReactNative)
public class TiktokOpensdkReactNative: NSObject {
    private static var pendingResolver: RCTPromiseResolveBlock?
    private static var pendingRejecter: RCTPromiseRejectBlock?
    private let serialQueue = DispatchQueue(label: "com.tiktok.sdk.serial")

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
        DispatchQueue.main.async { [weak self] in
            self?.downloadAndShareMedia(mediaUrls: mediaUrls, isImage: isImage, isGreenScreen: isGreenScreen, resolver: resolver, rejecter: rejecter)
        }
    }
    
    private func downloadAndShareMedia(mediaUrls: [String], isImage: Bool, isGreenScreen: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        NSLog("TikTok SDK: Preparing media for sharing")
        let dispatchGroup = DispatchGroup()
        var localIdentifiers: [String] = []
        
        mediaUrls.forEach { urlString in
            guard let url = URL(string: urlString) else {
                NSLog("TikTok SDK: Invalid media URL: \(urlString)")
                return
            }
            
            dispatchGroup.enter()
            downloadMedia(from: url, isImage: isImage) { [weak self] identifier in
                self?.serialQueue.async {
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    if let identifier = identifier {
                        localIdentifiers.append(identifier)
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            if localIdentifiers.isEmpty {
                NSLog("TikTok SDK: No media saved successfully")
                rejecter("SAVE_ERROR", "Failed to save media", nil)
                return
            }
            self?.performTikTokShare(localIdentifiers: localIdentifiers, isImage: isImage, isGreenScreen: isGreenScreen, resolver: resolver, rejecter: rejecter)
        }
    }
    
    private func downloadMedia(from url: URL, isImage: Bool, completion: @escaping (String?) -> Void) {
        var createdIdentifier: String?
        
        PHPhotoLibrary.shared().performChanges({
            let assetCreationRequest = PHAssetCreationRequest.forAsset()
            if isImage {
                assetCreationRequest.addResource(with: .photo, fileURL: url, options: nil)
            } else {
                assetCreationRequest.addResource(with: .video, fileURL: url, options: nil)
            }
            
            createdIdentifier = assetCreationRequest.placeholderForCreatedAsset?.localIdentifier
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    NSLog("TikTok SDK: Media saved successfully")
                    completion(createdIdentifier)
                } else {
                    NSLog("TikTok SDK: Error saving media: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                }
            }
        }
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