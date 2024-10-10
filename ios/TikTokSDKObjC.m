#import "TikTokSDKObjC.h"
#import <TiktokOpensdkReactNative-Swift.h>

@implementation TikTokSDKObjC

+ (BOOL)handleOpenURL:(NSURL *)url {
    return [TikTokURLHandler handleOpenURL:url];
}

+ (BOOL)handleUserActivity:(NSUserActivity *)userActivity {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] && userActivity.webpageURL) {
        return [TikTokURLHandler handleOpenURL:userActivity.webpageURL];
    }
    return NO;
}

@end