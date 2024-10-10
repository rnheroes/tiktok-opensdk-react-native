import Foundation
import TikTokOpenSDKCore
import TikTokOpenShareSDK

@objc(TiktokOpensdkReactNative)
class TiktokOpensdkReactNative: NSObject {
    
    @objc static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    @objc(share:mediaUrls:isImage:isGreenScreen:resolver:rejecter:)
    func share(_ clientKey: String, mediaUrls: [String], isImage: Bool, isGreenScreen: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        // Set up the share request
        let mediaType: TikTokShareMediaType = isImage ? .image : .video
        let shareRequest = TikTokShareRequest(localIdentifiers: mediaUrls, mediaType: mediaType, redirectURI: "your-redirect-uri-here")
        
        // Send the share request
        shareRequest.send { response in
            guard let shareResponse = response as? TikTokShareResponse else {
                rejecter("SHARE_ERROR", "Invalid response", nil)
                return
            }
            
            if shareResponse.errorCode == .noError {
                resolver(["isSuccess": true])
            } else {
                resolver([
                    "isSuccess": false,
                    "errorCode": shareResponse.errorCode.rawValue,
                    "errorMsg": shareResponse.errorDescription ?? "Unknown error"
                ])
            }
        }
    }

    @objc public class TikTokURLHandler: NSObject {
        @objc public static func handleOpenURL(_ url: URL) -> Bool {
            return TikTokOpenSDKCore.TikTokURLHandler.handleOpenURL(url)
        }
    }
}
