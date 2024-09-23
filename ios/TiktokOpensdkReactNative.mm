#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(TikTokSDKWrapper, NSObject)

RCT_EXTERN_METHOD(login:(NSArray *)scopes
                  redirectURI:(NSString *)redirectURI
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(share:(NSArray *)localIdentifiers
                  mediaType:(NSString *)mediaType
                  redirectURI:(NSString *)redirectURI
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
