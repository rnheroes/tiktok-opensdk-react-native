# TikTok OpenSDK React Native

This package provides a React Native wrapper for the TikTok OpenSDK, allowing you to integrate TikTok sharing functionality into your React Native applications.

## Installation

```bash
npm install tiktok-opensdk-react-native
# or
yarn add tiktok-opensdk-react-native
````

## Usage

```javascript
import TikTokOpenSDK from 'tiktok-opensdk-react-native';

// ...

try {
  const result = await TikTokOpenSDK.share(
    ['path/to/media1', 'path/to/media2'],
    false, // isImage (true for images, false for videos)
    false  // isGreenScreen
  );

  if (result.isSuccess) {
    console.log('Share successful!');
  } else {
    console.error('Share failed:', result.errorMsg);
  }
} catch (error) {
  console.error('Error sharing to TikTok:', error);
}
```

# API

## `TikTokOpenSDK.share(mediaPaths: string[], isImage: boolean, isGreenScreen: boolean): Promise<ShareResult>`
<!-- Shares media to TikTok.

mediaUrls: Array of local media file URLs to share
isImage: Set to true for images, false for videos
isGreenScreen: Set to true to use green screen effect (TikTok app only) -->
Shares media to TikTok.

### Parameters

- `mediaPaths: string[]` - Array of local media file paths to share
- `isImage: boolean` - Set to `true` for images, `false` for videos
- `isGreenScreen: boolean` - Set to `true` to use green screen effect (TikTok app only)

Returns a Promise that resolves to a `ShareResult` object.

```typescript
type ShareResult = ShareSuccessResult | ShareErrorResult;

interface ShareSuccessResult {
  isSuccess: true;
}

interface ShareErrorResult {
  isSuccess: false;
  errorCode: number;
  subErrorCode?: number;
  shareState?: number;
  errorMsg: string;
}
```

# iOS Setup

Minimum iOS version: 12.0
Minimum Xcode version: 10.0

1. Link the package to your project by running `npx pod-install` or `cd ios && pod install`.
2. Add the TikTok OpenSDK client key to your `Info.plist` file:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>tiktokopensdk</string>
    <string>tiktoksharesdk</string>
    <string>snssdk1180</string>
    <string>snssdk1233</string>
</array>
<key>TikTokClientKey</key>
<string>$TikTokClientKey</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>$TikTokClientKey</string>
    </array>
  </dict>
</array>
```

3. Add NSPhotoLibraryUsageDescription to your `Info.plist` file:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>$(PRODUCT_NAME) would like to save photos to your photo library</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>$(PRODUCT_NAME) would like to access your photo library</string>
```

4. Update your AppDelegate.m

```objc
#import <tiktok_opensdk_react_native/tiktok_opensdk_react_native-Swift.h>

@implementation AppDelegate

// ... other methods ...

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
  BOOL handled = NO;

  if ([TiktokOpensdkReactNative handleOpenURL:url]) {
      handled = YES;
  }

  // Handle other custom URL schemes

  return handled;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
  BOOL handled = NO;

  if ([TiktokOpensdkReactNative handleUserActivity:userActivity]) {
      handled = YES;
  }

  // Handle other user activities

  return handled;
}

@end
```

# Android Setup

Minimum Android version: API level 21 (Android 5.0 Lollipop) or later

1. Add the TikTok SDK repository to your project-level build.gradle:

```gradle
repositories {
    maven { url "https://artifact.bytedance.com/repository/AwemeOpenSDK" }
}
```

2. Add the TikTok SDK dependencies to your app-level build.gradle

```gradle
dependencies {
    implementation 'com.tiktok.open.sdk:tiktok-open-sdk-core:2.3.0'
    implementation 'com.tiktok.open.sdk:tiktok-open-sdk-share:2.3.0'  // for share API
}
```

3. For Android 11 and higher, add the following to your AndroidManifest.xml:

```xml
<queries>
    <package android:name="com.zhiliaoapp.musically" />
    <package android:name="com.ss.android.ugc.trill" />
</queries>
```

4. Add client key to your strings.xml file:

```xml
<string name="tiktok_client_key">$TikTokClientKey</string>
```

5. Add metadata to your AndroidManifest.xml file:

```xml
<meta-data android:name="com.tiktokopensdkreactnative.tiktok.CLIENT_KEY" android:value="@string/tiktok_client_key" />
```

6. Add this provider to your AndroidManifest.xml:
```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.tiktokopensdkfileprovider"
    android:exported="false"
    android:grantUriPermissions="true"
    tools:replace="android:authorities">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/filepaths"
        tools:replace="android:resource" />
</provider>
```

7. Create a filepaths.xml file in your res/xml folder:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <cache-path name="cached_files" path="." />
</paths>
```

# Troubleshooting

If you encounter any issues, please check the TikTok OpenSDK documentation for more detailed setup instructions and troubleshooting tips.

# License

MIT

# Roadmap

- [ ] Refactor API to use a single `share` method with an options object
- [ ] Add support for login and authorization APIs
- [ ] Send shareShate for error handling in iOS
- [ ] Add support redirectUri for both platforms
- [ ] Add custom client key for both platforms
- [ ] Refactor API, pass client key, redirectUri, and callerScheme as last parameters
- [ ] Add support remote media URLs
- [ ] Handle photo library permissions in native side
- [ ] Refactor whole android part
- [ ] Check if tiktok app is installed
- [ ] Remove isImage parameter and detect media type automatically