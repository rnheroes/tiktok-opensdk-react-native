#import "TikTokSDKObjC.h"
#import <tiktok_opensdk_react_native/tiktok_opensdk_react_native-Swift.h>

@implementation TikTokSDKObjC

+ (BOOL)handleOpenURL:(NSURL *)url {
    return [[TiktokOpensdkReactNative TikTokURLHandler] handleOpenURL:url];
}

+ (BOOL)handleUserActivity:(NSUserActivity *)userActivity {
    return [[TiktokOpensdkReactNative TikTokURLHandler] handleUserActivity:userActivity];
}

@end
