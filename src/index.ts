import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'tiktok-opensdk-react-native' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const TiktokOpensdkReactNative = NativeModules.TiktokOpensdkReactNative
  ? NativeModules.TiktokOpensdkReactNative
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export interface TikTokOpenSDKLoginResult {
  authCode: string;
  grantedPermissions: string[];
  authError?: string;
  authErrorDescription?: string;
}

export interface TikTokOpenSDKShareResult {
  isSuccess: boolean;
  errorCode: number;
  subErrorCode: number;
  errorMsg: string;
}

export interface TikTokSDKType {
  login: (
    clientKey: string,
    redirectUri: string
  ) => Promise<TikTokOpenSDKLoginResult>;
  handleLoginResult: (
    intentUri: string,
    redirectUri: string
  ) => Promise<TikTokOpenSDKLoginResult>;
  share: (
    clientKey: string,
    mediaUrls: string[],
    isImage: boolean,
    isGreenScreen: boolean
  ) => Promise<void>;
  handleShareResult: (intentUri: string) => Promise<TikTokOpenSDKShareResult>;
  grantUriPermission: (uri: string) => Promise<void>;
}

const TikTokOpenSDK: TikTokSDKType = {
  login: (
    clientKey: string,
    redirectUri: string
  ): Promise<TikTokOpenSDKLoginResult> => {
    return TiktokOpensdkReactNative.login(clientKey, redirectUri);
  },

  handleLoginResult: (
    intentUri: string,
    redirectUri: string
  ): Promise<TikTokOpenSDKLoginResult> => {
    if (Platform.OS === 'android') {
      return TiktokOpensdkReactNative.handleLoginResult(intentUri, redirectUri);
    }
    return Promise.reject('Not implemented for this platform');
  },

  share: (
    clientKey: string,
    mediaUrls: string[],
    isImage: boolean,
    isGreenScreen: boolean
  ): Promise<void> => {
    return TiktokOpensdkReactNative.share(
      clientKey,
      mediaUrls,
      isImage,
      isGreenScreen
    );
  },

  handleShareResult: (intentUri: string): Promise<TikTokOpenSDKShareResult> => {
    if (Platform.OS === 'android') {
      return TiktokOpensdkReactNative.handleShareResult(intentUri);
    }
    return Promise.reject('Not implemented for this platform');
  },

  grantUriPermission: (uri: string): Promise<void> => {
    if (Platform.OS === 'android') {
      return TiktokOpensdkReactNative.grantUriPermission(uri);
    }
    return Promise.reject('Not implemented for this platform');
  },
};

export default TikTokOpenSDK;
