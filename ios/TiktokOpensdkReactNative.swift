import Foundation
import TikTokOpenSDKCore
import TikTokOpenAuthSDK
import TikTokOpenShareSDK

@objc(TiktokOpensdkReactNative)
class TiktokOpensdkReactNative: NSObject {
  
  @objc
  func login(_ scopes: [String], redirectURI: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    let authRequest = TikTokAuthRequest(scopes: scopes, redirectURI: redirectURI)
    authRequest.send { response in
      guard let authResponse = response as? TikTokAuthResponse else {
        rejecter("ERROR", "Failed to cast response", nil)
        return
      }
      
      if authResponse.errorCode == .noError {
        resolver(["code": authResponse.code])
      } else {
        rejecter("ERROR", authResponse.errorDescription ?? "Unknown error", nil)
      }
    }
  }
  
  @objc
  func share(_ localIdentifiers: [String], mediaType: String, redirectURI: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    let mediaType: TikTokMediaType = mediaType == "video" ? .video : .image
    let shareRequest = TikTokShareRequest(localIdentifiers: localIdentifiers, mediaType: mediaType, redirectURI: redirectURI)
    shareRequest.send { response in
      guard let shareResponse = response as? TikTokShareResponse else {
        rejecter("ERROR", "Failed to cast response", nil)
        return
      }
      
      if shareResponse.errorCode == .noError {
        resolver(["success": true])
      } else {
        rejecter("ERROR", shareResponse.errorMessage ?? "Unknown error", nil)
      }
    }
  }
}