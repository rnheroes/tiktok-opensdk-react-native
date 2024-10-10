#import "TikTokSDKObjC.h"
#import <TiktokOpensdkReactNative-Swift.h>

@implementation TikTokSDKObjC

+ (BOOL)handleOpenURL:(NSURL *)url {
    return [TikTokURLHandler handleOpenURL:url];
}

@end