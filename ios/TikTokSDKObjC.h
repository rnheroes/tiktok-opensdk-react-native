#import <Foundation/Foundation.h>

@interface TikTokSDKObjC : NSObject

+ (BOOL)handleOpenURL:(NSURL *)url;
+ (BOOL)handleUserActivity:(NSUserActivity *)userActivity;

@end
