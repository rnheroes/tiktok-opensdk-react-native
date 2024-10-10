#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(TiktokOpensdkReactNative, NSObject)

RCT_EXTERN_METHOD(share:(NSString *)clientKey
                  mediaUrls:(NSArray *)mediaUrls
                  isImage:(BOOL)isImage
                  isGreenScreen:(BOOL)isGreenScreen
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
