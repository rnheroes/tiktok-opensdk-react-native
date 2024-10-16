#import <React/RCTBridgeModule.h>

@interface TiktokOpensdkReactNative : NSObject <RCTBridgeModule>
+ (BOOL)handleOpenURL:(NSURL *)url;
+ (BOOL)handleUserActivity:(NSUserActivity *)userActivity;
@end
